# 媒体合成管线 (media_compose_v1) — API 对接文档

> **范围**:多片段视频拼接 / 转场 / 混音 / 字幕烧录 / 规格归一的平台合成能力,
> 以 **task-as-primary 管线**形态实装于 Creation BC,复用 `POST /v1/tasks` 任务通道
> (与 [storeshot-pipeline.md](storeshot-pipeline.md) 同机制,本文只写差异面)。
> **事实驱动**:每条契约标注 `文件:行号`。核对时间 2026-06-10。

---

## 0. 真实实现状态

| 项 | 状态 | 证据 |
|---|---|---|
| 处理器 `ffmpeg_media_compose` | ✅ fx 注册 | `internal/creation/fx_module.go`(processors group)、`infra/postprocess/ffmpeg_media_compose_processor.go` |
| 模板 `media_compose_v1` 入库 | ✅ active,cpu_intensive(dev 已验证) | `docs/migrations/p_media_compose_v1.sql`(幂等+自校验) |
| 定价 per_second 4 档 | ✅ default/free/member/enterprise = 1/2/1/1 credit/s,min 10/12/8/6 | 同上 SQL;`wal_credit_pricing_rules` 实查 |
| 定价缺失 strict 拒绝 | ✅ 50830(全体管线生效) | `submit_task_handler.go::handlePipelineSubmit`、`errors.go::ErrPipelinePricingMissing` |
| 提交期校验+富化 | ✅ ComposeSubmitValidator | `app/command/compose_submit_validator.go` |
| 媒体元数据回填 | ✅ MediaProbeWorker(60s 扫描,ffprobe) | `app/command/media_probe_worker.go`、`infra/postprocess/ffprobe_prober.go` |
| 终态 Outbox | ✅ TaskCompleted/TaskFailed(管线级,惠及全部 task-as-primary) | `infra/postprocess/worker.go::PipelineOutboxPublisher` |
| 真机 E2E | ✅ `go test -tags=ffmpeg_real -run TestRealMediaCompose` | `ffmpeg_media_compose_real_test.go` |

**上线前置**:① 目标库跑 `docs/migrations/p_media_compose_v1.sql`;② 宿主 `apt install ffmpeg fonts-noto-cjk`
(deploy README §6.A);③ worker unit 含资源限额(`genaistudio-worker.service` MemoryMax/CPUWeight)。

## 1. 对接流程

```
① 上传素材    POST /v1/uploads/sign + finalize(双段直传, 见 creation.md)
              → 等 MediaProbeWorker 回填时长 (≤60s; 未回填提交返 40812)
② 提交        POST /v1/tasks {pipeline_code:"media_compose_v1", params:{<compose_spec>}}
              → 202 {task_id, poll_url, estimate_ms}
③ 轮询/SSE    GET /v1/tasks/:bid (或 /stream) → pending→processing→completed/failed
④ 取产物      output_metadata.final_urls[0](快路径)或 candidates[0].url(R2 托管, content_type=video)
```

## 2. params = compose_spec(契约源:`domain/postprocess/compose_spec.go`)

```jsonc
{
  "spec_version": "1.0",
  "segments": [                              // 1..20, 顺序即拼接序; 视频段与静图段可混排
    {"asset_bid": "<uuid>", "trim_in_ms": 0, "trim_out_ms": 5000},
    // 视频段: trim_out_ms 省略 = 到素材末尾; 素材 content_type=video 且已回填时长
    {"asset_bid": "<uuid>", "duration_ms": 3000, "motion": "zoom_in"},
    // 静图段 (FT-4): duration_ms 500..30000 声明展示时长 (即声明本段为图);
    // motion = none|zoom_in|zoom_out|pan_left|pan_right (ken-burns 运镜, 省略=none);
    // 素材 content_type=image 且已回填宽高; trim_* 不适用 (传了 40820);
    // 画面 cover-crop 充满画布 (裁边), 区别于视频段 pad 信箱; 段间转场/计价与视频段一致
    {"asset_bid": "<uuid>", "narration_asset_bid": "<uuid>", "motion": "zoom_out"}
    // 逐段旁白 (FT-1, 仅静图段): audio 资产在本段时间窗内播放 (进原声 bed 层,
    // 与 bgm 混音/被 duck 语义不变) — 短剧"每镜一句台词"承载;
    // duration_ms 可省 = 旁白时长 + 600ms padding 自动推导 (显式时须 ≥ 旁白时长)
  ],
  "transitions": [                           // 0 条(全硬切)或 len(segments)-1 条
    {"type": "fade", "duration_ms": 500}     // none|fade|dissolve|wipeleft|wiperight; 200..2000ms
  ],
  "audio": {
    "original": "keep",                      // keep|mute|duck(旁白压低原声)
    "tracks": [                              // ≤2; asset 须 content_type=audio
      {"asset_bid": "<uuid>", "role": "bgm", "gain_db": -8, "loop": true},
      {"asset_bid": "<uuid>", "role": "narration", "duck_others": true}
    ]
  },
  "subtitles": {                             // 可选; inline 结构化, 不收字幕文件
    "events": [{"start_ms": 0, "end_ms": 1500, "text": "你好"}],   // ≤500 条
    "style_preset": "default"                // default|large|outline(白名单, 禁自由样式)
  },
  "output": {"preset": "1080p_vertical"}     // 1080p_vertical|1080p_horizontal|720p_vertical
}
```

限额:输出声称时长 ≤ **300s**;segments ≤ 20;字幕单条 ≤ 200 字符。
服务端注入键(`_compose_media` / `duration`)客户端**不可传**(传了会被覆盖,`compose_submit_validator.go`)。

### 短剧/MV 方言(FT-1/3,旗舰 Workflow 模板的 assemble 入参)

params 含 `shots` 即启用(`compose_short_drama_dialect.go` 提交期翻译为标准 spec,逐镜对位/时长对齐/字幕时间轴在服务端 Go 完成 — CEL 表达不了跨数组算术):

```jsonc
{
  "shots":      [{"line": "台词", "duration_ms": 4200}],  // script/分镜 LLM 输出; duration_ms 仅无旁白形态必填
  "images":     [/* Runtime batch items[] | {"asset_bid"} | "bid" */],  // 与 shots 等长
  "narrations": [/* 同上 */],                              // 可选: 有 → 短剧形态 (逐镜旁白定段长); 无 → MV 形态
  "music_asset_bid": "<uuid>",                             // 可选 (MV): 原曲进 bgm 轨
  "style":  {"motion": "auto", "transition": "dissolve", "transition_ms": 400, "subtitle_preset": "default"},
  "output": {"preset": "1080p_vertical"}
}
```

语义:`motion=auto` 交替 zoom_in/zoom_out;字幕 = 台词跟随镜头时间窗(累计时长 − 转场重叠);batch 失败占位项(status≠succeeded)**整镜跳过**(`on_partial=continue` 容忍,全失败 40820);batch item 取 `candidates[0].asset_bid`(workflow 任务候选自动固化产生,`outbox_publisher.go::autoKeepWorkflowCandidates`)。

## 3. 计费

- `cost_unit=per_second`,量纲 = 声称输出秒(服务端从 spec 推导:Σ片段时长 − Σ转场重叠,向上取整)。
- 提交时冻结全额;**原子产物**:成功全额 Confirm / 失败全额 Refund(无 partial,`worker.go::decidePipelineSettlement` partial=false 分支)。
- 例:60s 成片 default 档 = 60 积分;不足 min_cost 按 min_cost。

## 4. 提交期错误(冻结前,零经济副作用)

| code | sentinel | 场景 |
|---|---|---|
| 40810 | ErrComposeAssetNotFound | asset_bid 不存在/非本账号 |
| 40811 | ErrComposeAssetNotReady | 素材未 finalize |
| 40812 | ErrComposeAssetNoDuration | 元数据未回填(稍后重试)/素材损坏 |
| 40813 | ErrComposeAssetMediaMismatch | 片段非 video / 音轨非 audio |
| 40820 | ErrComposeSpecInvalid | spec 结构/枚举非法 |
| 40821 | ErrComposeSpecLimitExceeded | trim 越界 / 输出 >300s |
| 50830 | ErrPipelinePricingMissing | 定价规则缺失(运维配置) |

执行期失败 → 任务终态 `failed`(`error_code=pipeline_failed`)+ 全额退款。

## 5. 执行与运维要点

- 队列:`queue:postprocess:batch`(cpu_intensive 模板自动降级 batch 优先级,`submit_task_handler.go::pipelinePriority`);处理器内并发信号量 = 1(单机防饿死)。
- 安全:filtergraph 由 spec 白名单编译(`media_compose_filter.go`),用户输入零注入面;ffmpeg 进程组超时击杀;临时盘配额预检。
- 字幕字体:宿主 `fonts-noto-cjk`(Noto Sans CJK,SIL OFL)。
