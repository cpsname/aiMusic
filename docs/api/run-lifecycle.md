# Run 生命周期与完成语义(单一事实源)

> R5-W1(2026-08-29)。本文是 Run 状态/事件/结算/事件流四类语义的**唯一定音表**;
> 与代码的一致性由 `tests/contract/run_lifecycle_test.go` 机器钉死(AST 抽取
> `vo.RunState/RunEvent` 全集 ↔ 本文注册表 ↔ 分类谓词 ↔ 状态机可达性,任一漂移即红)+
> `internal/runtime/app/command/run_lifecycle_settlement_test.go`(终态×钱包原语行为契约)。
> 变更纪律见 §7。设计出处:`docs/architecture/harness-agent-monolith-upgrade-design.md` §4/§6-W1。

## 1. 完成语义十态梯子

「完成」不是一个词。任务书(R5 §5.5)要求的十个语义位,在本仓各有持久化载体——
**不得用单一 success/completed/ack 混称**;对客文案与内部日志引用完成语义时以本表用词为准:

| 梯位 | 语义 | 载体(证据) |
|---|---|---|
| Admission | 请求过闸(权限/归属/内容审/幂等/E5 并发策略/技能硬闸),**资金冻结之前** | `send_message_handler.go` 闸链;排队消息 = Admission 后零计费驻留 |
| Local Commit | run+消息+outbox 同事务落库 | `ExecuteInTransaction`(Outbox-first) |
| Execution Started | worker 认领开跑(与 Commit 分离即 `created` 存在的意义) | lease TryLock + 状态机首拍转移 |
| Step Completed | 单拍产物落库 | `rt_run_steps` 行 + **`rt_runs` 行乐观锁同事务**(并发同步的裁决点;勘误 2026-08-31:`rt_run_steps` 的唯一约束含分区键 `created_at`,**不去重**。三条路径见 §12)|
| Checkpoint Persisted | scratchpad 随 Step 同事务 | `CompleteStep` 内 run.Update 同 tx;E7 装置钉「模型可见≡已持久化」 |
| Projection Updated | 会话事件流投影(最终一致,补传事实源) | `rt_conversation_events` conv_seq + `schema_version` |
| External Effect Confirmed | 外部副作用确认,**与 Run 终态分离** | 资金:freeze→Confirm/Partial/Refund+守护行+对账族;能力:`cap_executions` `succeeded`(证据)vs `outcome_unknown`(兜底,禁盲重);工具:`rt_tool_calls` 终态+双文案 |
| Run Completed | 成功终态 + 实结 | §4 矩阵 succeeded 行 |
| Run Failed | 失败/超时终态 + 退款(默认) | §4 矩阵 failed/timeout 行 |
| Run Cancelled | 取消终态 + 退款(默认) | §4 矩阵 cancelled 行 |

## 2. Run 状态注册表(11 态)

来源:`internal/runtime/domain/valueobject/run_state.go`。分类谓词 `IsActive/IsAwaiting/IsTerminal`
与本表逐行一致(contract 断言)。

| 状态 | 类别 | 含义 | 崩溃/丢消息后的恢复面 |
|---|---|---|---|
| `created` | active | Local Commit 完成、执行未开始 | RunRecoveryWorker stale 扫描重入队 |
| `planning` | active | (微观态,脉冲间通常不落盘,见 §3 注) | 同上 |
| `acting` | active | 拍循环推进中(ReAct 自环驻留态) | lease TTL 自释 + Recovery 重入队 + poison 计数终结 |
| `observing` | active | (微观态) | 同上 |
| `reflecting` | active | (微观态) | 同上 |
| `awaiting_human_input` | awaiting | 挂起等人工(workflow 审批 / `__budget_topup__` / E1 `tool:` 审批单) | 唤醒入口 SubmitHumanApproval;审批超时按 timeout_action 决议 |
| `awaiting_creation` | awaiting | 挂起等异步产物(creation 任务 / WK-02+E4 子 Run) | outbox 终态事件唤醒;AwaitingCreationReconciler 超时兜底 |
| `paused` | awaiting | R5-W2 用户主动暂停(拍间生效,持久化;冻结在途、**超时钟不停** D-R5-03) | 唤醒入口 `POST /runs/:bid/resume`;超 effectiveDeadline 由 RunRecoveryWorker 置 timeout 退款(不重入队、不进 poison 计数) |
| `succeeded` | terminal | 成功终态 | 不可再转移(`ErrRunTerminated`) |
| `failed` | terminal | 失败终态 | 同上 |
| `cancelled` | terminal | 用户/系统取消终态 | 同上 |
| `timeout` | terminal | 超时终态(对客投影见 §6) | 同上 |

**队列语义**:指向 awaiting 态 run 的队列消息一律陈旧/重复投递,消费侧 Ack 丢弃(M0-R3);
E5 会话并发计数 = active ∪ awaiting(排队串行不被挂起击穿)。

## 3. 事件注册表(13 事件)与合法转移

来源:`run_state.go:65-81` + 唯一转移入口 `domain/service/run_state_machine.go`
(**严禁**绕过 `Transition()` 直接赋值 run.State)。

| 事件 | 合法源 → 目标 |
|---|---|
| `start_planning` | created → planning |
| `start_acting` | created/planning → acting |
| `start_observing` | acting → observing |
| `start_reflecting` | observing → reflecting |
| `continue` | created(首拍)/acting(自环)/reflecting → acting |
| `finish` | created/acting/reflecting → succeeded |
| `request_human_input` | created/acting/reflecting → awaiting_human_input |
| `resume_human_input` | awaiting_human_input → acting |
| `request_creation` | created/acting/reflecting → awaiting_creation(creation 任务与子 Run 委派共用) |
| `resume_creation` | awaiting_creation → acting |
| `pause` | created/planning/acting/observing/reflecting → paused(R5-W2;awaiting_* 不可 pause — `ErrRunNotPausable` 40939) |
| `resume_paused` | paused → acting(R5-W2,重入队续跑) |
| `fail` / `cancel` / `timeout` | 任何非终态 → failed / cancelled / timeout(通用终态边;**paused 亦可被 cancel/timeout** — 冻结经既有退款矩阵收口) |

> **脉冲模型注(FT-7)**:worker 单拍 = Plan→Act→Reflect→CompleteStep 单次转移;
> planning/observing/reflecting 微观态脉冲间通常不持久化,决策事件的实际源态
> = created(首拍)与 acting(续拍)——故 created 拥有全部决策出边。

## 4. 终态 × 资金结算矩阵

实装:`complete_step_handler.go`(事务外结算;失败留守护行交 reconciler 24h+ 兜底,
**不阻塞终态**)。行为契约:`run_lifecycle_settlement_test.go`。

| 终态 | 条件 | 钱包原语 | 落账扣费 confirmedCredits |
|---|---|---|---|
| succeeded | charged=UsageCredits ≥ estimate 或 ≤ 0 | `ConfirmFreeze`(全额;超支差额只记 shortfall 台账不追收) | EstimatedCredits |
| succeeded | 0 < charged < estimate | `PartialConfirmFreeze`(实结,余额自动退回) | charged |
| failed / cancelled / timeout | 默认 | `RefundFreeze`(全额退款,B-6) | 0(显式写 0,防「失败却显示消费」) |
| failed / cancelled / timeout | `SettlePartialDelivery=true`(流式已交付部分,HS-1) | 同 succeeded 矩阵(estimate 不出用量→全额 Confirm) | 同 succeeded |
| failed / cancelled / timeout | config `runtime.charge_partial_on_failure=true` 且 UsageCredits>0 | `PartialConfirmFreeze(min(usage,estimate))` | min(usage,estimate) |

幂等冲突(Step 重投)与 FreezeID=0(无冻结)**不触发任何钱包调用**。
结算成功 → reconciliation 行流转终态(confirmed/refunded)+ `charged_credits` 写回 run。

## 5. 终态 outbox 事件

实装:`complete_step_handler.go::saveTerminalEvent`(幂等键 `<run_bid>:<terminal>`;
子 Run 附 parent 三元组供唤醒路由)。

| 终态 | 事件 | 注意 |
|---|---|---|
| succeeded | `runtime.run_succeeded` | 携 FinalAnswer/实扣/memory 上下文 |
| failed | `runtime.run_failed` | 携 ErrorCode/ErrorMessage |
| cancelled | `runtime.run_cancelled` | **不携 parent 维度**(已知边界:被取消的子 Run 由 AwaitingCreationReconciler 收口父) |
| timeout | `runtime.run_failed`,**ErrorCode=`TIMEOUT`** | 态≠事件名:timeout 复用 failed 事件通道 |

非终态事件(R5-W2):pause → `runtime.run_paused` / resume(paused 分支)→ `runtime.run_resumed`,均投影 SSE `run.status`(`state:"paused"` / `state:"acting"`),零资金动作。

## 6. 对客投影(SSE `run.status`)

`event_consumer.go::projectRun*` → payload `{run_bid, state, schema_version, ...}`:
succeeded→`state:"succeeded"`(+credits_charged)· failed **与 timeout** →`state:"failed"`(+error_code,
timeout 即 `TIMEOUT`)· cancelled→`state:"cancelled"`。客户端判超时看 error_code,不看独立状态。

## 7. 变更纪律

新增/修改状态或事件的**完整**动作序(缺一即 contract 红):
① `vo/run_state.go` 常量 + 分类谓词;② 本文 §2/§3 注册表行;③ `run_lifecycle_test.go`
canonical 表;④ 状态机 `lookupTransition` 边;⑤ 若为终态:§4 结算行 + §5 事件行 +
`saveTerminalEvent`/结算 switch + settlement 契约用例;⑥ ent schema 枚举 + expand-only 迁移。
删除/改语义 = 破坏性变更,须走双版本消费窗口评审。

## 8. 外部副作用提交五态(M-A / D-021,`shared/errs.CommitState`)

十态梯子的 **External Effect Confirmed** 位在调用链上游展开为提交五态——**网络超时 ≠ 失败**:

| 提交态 | 语义 | 允许的动作 |
|---|---|---|
| `not_submitted` | 未触达上游 | **唯一可安全重试的态** |
| `submitted` | 已发出,回执未知前 | 禁重提;等待/查询 |
| `provider_accepted` | 上游已受理(job id 已落盘,如 `gen_tasks.upstream_task_id`) | 只许查询/轮询/下载,重提=新副作用 |
| `result_committed` | 结果已提交 | 重试=幂等去重返回 |
| `unknown` | 结果未知(超时/断连于 submitted 之后) | **先对账,禁盲重试**(§9) |

**一 Attempt 一 Submit**:提交态 ≥ `submitted` 后禁同 Attempt 重提。消费面守卫
`tests/archtest/ma_guards_test.go::TestMA_SubmitAsyncCallsiteWhitelist`(新调用点必须先落
"提交前查上游锚已落盘"防线,`task_consumer.go:1672` 为正典)。

## 9. 共享重试预算与 Unknown 五不纪律(M-A / D-005 / D-006)

**词汇**:`internal/shared/errs` —— 错误代数 13 类封闭集;可重试性 = `ShouldRetry(Class, CommitState)`
**唯一裁决点**(仅 `provider_error/provider_timeout/internal` × `not_submitted` 三组合为真;
业务终态与 `outcome_unknown` 永不重试)。

**共享 AttemptBudget**(S11 根治):`runtime.worker.run_consumer.attempt_budget_max_attempts > 0`
时,RunConsumer 每拍构造一份预算注入 ctx —— resilient_adapter 每次上游调用 `Consume` 名额
(唯一消费点),llm_invoker 的质量重试/failover 只查余量;退避走统一阶梯
400ms→2s→10s→60s→300s(补分钟级)。预算窗口恒 = MinIdle(重试烧不穿 XAUTOCLAIM 重投窗口)。
**0(默认)= 未启用**,各层沿用自身常数,行为逐字节不变;dev 已开 6 验证。
旧最坏放大:消息层 5 × 模型链 N × 质量重试 3 × (1+MaxRetries) —— 预算模式下总上游调用 ≤ 预算。

**Unknown 五不纪律**(commitState=`unknown` / `outcome_unknown` 期间):不新 Submit ·
不释放预算/冻结 · 不标失败 · 不宣称取消成功 · 先四路查证(上游 Poll / 副作用回执 /
账单行 / 对象存储 HEAD+Hash)再收敛。收敛出口仅 settle / refund / 超窗转人工。
各域案件载体:`cap_executions.outcome_unknown` 行 · `rt_tool_calls` 终态+双文案 ·
`gen_tasks` reconciliation 家族(F6)——跨域超窗巡检归 SLI 巡检面(G4),不建重复表。

## 10. 委派资源语义(M-D/K3:深度 × **宽度** × 额度)

E4 起委派只封了**链的长度**(`vo.MaxDelegationDepth = 2`)。长度封不住**宽度**:
一拍内登记 N 个委派节点就是 N 个子 Run 各自冻结,而 N 由模型决定。M-D 补两道资源闸,
并把父子关系落列以支持聚合。

| 维度 | 常数/来源 | 闸位 | 拒绝语义 |
|---|---|---|---|
| 深度 | `vo.MaxDelegationDepth=2` | 工具面预隐藏 → dispatch 兜底 → StartSubRun 硬拒 | 配置性(重试无意义) |
| **宽度** | `vo.MaxDelegationFanout=4` | dispatch 预闸(零事件零冻结)→ StartSubRun **父行加锁**计数 | **时序性**(等兄弟跑完即可) |
| **额度** | `rt_runs.delegation_budget_credits` | StartSubRun 划拨(clamp)+ 锁内复算 | 时序性/终局(视是否有子代在途) |

**额度模型**(不是资金转移 —— 子 Run 仍自持 freeze,R10 不变):

- 根 Run:`DelegationBudgetForRoot(自身预留) = 自身预留 × MaxDelegationFanout`,由
  `entity.NewRun` 在构造期赋值(放构造函数而非各建 Run 处 —— 漏一处的后果是"该 Run 的
  子代不受额度约束",而零值是合法值,编译器与测试都不会喊);
- 子 Run:额度 = **它自己拿到的划拨额**,逐层不增 ⇒ 整棵树在途预留 ≤ 9× 根预留(深度 2);
- 划拨:`alloc = min(请求预留, 父剩余)`;`父剩余 = 父额度 − (Σ在途子代预留 + Σ终态子代实扣)`。
  两桶口径不同是**故意**的:在途按预留(钱正冻着),终态按实扣(多冻的已退)——
  于是一个便宜的子代跑完会把额度还给兄弟,与"打断即省钱"同一条经济学;
- 剩余 ≤ 0 → 拒绝(零冻结);`0` 额度 = 未显式划拨(历史行)→ 按父自身预留派生。

**并发正确性**:竞争对象是**尚不存在的行**,无行可锁,故在共同祖先上串行化 ——
`LockDelegationLedger` 先 `SELECT … FOR UPDATE` 锁父行再聚合(父此刻恒为
`awaiting_creation`,无人与之争锁)。无锁预闸只为把常见拒绝挡在 Freeze 之前
(拒绝走冻结-退款往返既浪费又脏账);权威判定恒在事务内的锁后复算。

**never-reject 的诊断分类**(E4 语义不变:委派失败 = 观察面事实,不是父的 error):
`ErrDelegationFanoutExceeded` / `ErrDelegationBudgetExhausted` 与深度/环/目标模式分立哨兵,
因为回给父的话术不同 —— 前者可等待,后者要么等要么自己干,配置性拒绝则重试多少次都一样。
两个新哨兵**恒与** `ErrSubRunGuardRejected` 一同包裹,既有"护栏拒绝=不可重试终态"的判定不变。

**父子关系落列**:`rt_runs.parent_run_id`(0=根)。scratchpad 的 `__parent_run_bid` 是
**点对点唤醒**的载体,继续保留;但扇出计数与成本上卷都是**聚合**,JSONB 上没有索引可用。
落列不改结算口径 —— 父账仍只认自己的 freeze/confirm 流水,子代成本只在读面
(`GET /v1/runs/:bid/delegation-tree`)上卷,零双写。

## 11. 中断矩阵(M-D/K4:4 类 × 2 时机)

「中断」不是一个新状态,是**四个既有动作的矩阵化**。词汇单一事实源
`internal/runtime/app/command/interruption_audit.go`(`InterruptionKind` ×
`InterruptionTiming`),与本表由 `tests/contract/interruption_matrix_test.go` 钉死。

**时机判定唯一点** `TimingForRunState`:run 处 active 五态(含 `created`)→
`mid_step`;`awaiting_*`/`paused`/终态 → `step_boundary`。判据只看**持久化状态**,
不看"worker 是否真的在跑"——后者不可观测。

`created` 判 `mid_step` 是**故意保守**:首拍的状态迁移要到 `CompleteStep` 才落库,
所以库里还写着 `created` 的 run 完全可能已经在调上游。判成 `step_boundary` 等于
假定"什么都没发生"就去取消,正是提交五态(§8)要防的那类错。

| 中断类 | `step_boundary` | `mid_step` | 结算 |
|---|---|---|---|
| `pause` | 拍间挂起,保预留、可恢复;超时钟不停(D-R5-03) | awaiting_* 不可 pause → `ErrRunNotPausable` 40939 | 无资金动作(冻结原样留着) |
| `cancel` | 直接终态;planned 下未启步骤落零成本占位(`PLAN_STEP_SKIPPED`) | ctx 传播中止;已提交上游的按**提交五态**(§8)分流:`submitted`+ 禁重提、等回执,`unknown` 走五不纪律 | 退款矩阵(§4);planned 走信封实结(见下) |
| `revise` | 旧版本终止 + 追加 `pln_plan_versions` 新行 + 旧报价 superseded → 新版本重报价重确认 | 在途步骤按 cancel 的 mid_step 规则收口,再切版本 | 旧信封按已执行部分实结,新版本另开信封 |
| `steer` | 拍间注入(E5 inject):不终止执行,把新意图并入下一拍 | 不在中途改写 scratchpad —— 注入落在最近安全点,期望态 CAS 裁并发(D-020) | 无(同一个 run 继续,预算不变) |

**打断结算式(planned)**:释放额 = `Σ(未执行步骤 est_credits)`,判据函数
`domain/service.ReleasedOnInterrupt`。这条式子之所以恒成立且**不需要退款动作**:
planned 只有信封一笔冻结,未执行步骤从不产生 `usage_credits`,信封按 Σusage
`PartialConfirm` 时差额由钱包自动退回(实证 `plan_envelope_settle_e2e_test.go`)。

**留痕**:中断事实走平台正统审计面 `shared/audit.Sink → obs_audit_logs`
(`domain=runtime`,`action=kind`,`action_detail`,`resource_id=run_bid`,
`after_state` 携 timing/plan 锚/freeze_id)。**不建 `rt_run_interruptions` 表** ——
"谁在何时改了什么"是 F2 审计家族语义,新建等于第八张审计方言表
(`/table-gate` 2026-08-29 驳回记录见 MECHANISM-REGISTRY §2)。金额不在留痕面复制:
释放额由零成本占位 Run 行推导,实结额落 F6 守护行的 `confirmed_amount`。

**超时处置的先后铁律(D-018)**:任何超时处置者(40min ctx / RunRecoveryWorker /
AwaitingCreationReconciler)必须**先赢得状态迁移**(乐观锁 CAS `state→timeout`)
才有权动钱;输者静默放弃。于是"判超时并退款"与"仍在跑并扣款"不可能并存 ——
契约测试 `tests/contract/interruption_matrix_test.go` 钉住"CAS 在钱之前"的调用序。

## 12. 同一步被完成两次:三条路径与各自的裁决点(U-1,2026-08-31)

Worker 重投(XAUTOCLAIM / asynq retry)、多实例同抢、恢复流程重放 —— 同一
`(run, sequence, attempt)` 被完成两次是**常态**而非异常。它有三条路径,**裁决点各不相同**:

| # | 何时发生 | 裁决点 | 结果 |
|---|---|---|---|
| ① **真并发** | 两个 worker 同时完成同一步,谁也没看见谁 | **`rt_runs` 行乐观锁 CAS**(`WHERE id=? AND version=?`),与 step 插入**同一个事务** | 输方命中 0 行 → `ErrVersionConflict` → 事务回滚,**它那条 step 插入一并撤销** |
| ② **串行重投** | 上一次已提交,消息被重投 | 事务**之前**的幂等前置检查 `stepRepo.FindByRunAndSequence` 看到已终态 step | 幂等返回成功:不报错、不多写、不重复结算 |
| ③ **同微秒撞键** | 两次插入的 `clock_timestamp()` 恰好相同 | `uk_rt_run_steps_idempotency` UNIQUE | `ErrStepIdempotencyConflict` → 视为幂等成功,跳过事件写入与钱包结算 |

### 12.1 ③ 是兜底,不是主防线(2026-08-31 勘误)

四处文档 + `rt_run_steps` 的表注释都曾写着「由 `UNIQUE(run_id, sequence, attempt)`
保证只落一条」。实际索引是

```
uk_rt_run_steps_idempotency ON rt_run_steps (run_id, sequence, attempt, created_at)
```

—— **分区表的唯一索引必须含分区键**,而 `created_at DEFAULT clock_timestamp()`
在同一事务内也会前进。两次插入只要差 1µs 就都能成功,**它不去重**。

所以路径 ③ 只在"两次插入拿到同一个微秒"时才触发,是兜底;真并发的裁决全部由
路径 ① 承担。把 ③ 当主防线的后果不是"少了一层",而是**三种拆法都没人拦**:

| 改法 | 后果 | 会不会被既有测试抓到 |
|---|---|---|
| 把 `runRepo.Update` 挪出事务 | 两条 step 行都留下 | 否(本批之前) |
| 去掉 `VersionEQ` 谓词 | 两方都成功 | 否 |
| 把 `ErrVersionConflict` 吞成成功 | 调用方以为两次都完成了 | 否 |

三种改法均已逐一**变异验证**:改坏 → 用例必红 → 复原。

### 12.2 载体

| 层 | 位置 | 守什么 |
|---|---|---|
| 真机行为 | `test/e2e/runtime/step_concurrency_e2e_test.go` | 恰 1 条 step 行 · 恰 1 条助手回复 · 恰一方 `ErrVersionConflict` · run 版本恰 +2 |
| 静态守卫 | `tests/archtest/optimistic_lock_guard_test.go` | ① 返冲突哨兵的仓储函数必须带 CAS 谓词(全仓 14 处)· ② step 插入与 run CAS 必须在事务闭包**主干**上(退进条件分支也算失守)· ③ 判定冲突只许 `errors.Is` |

两层缺一不可:e2e 证明机制真的成立(要真 PG,`RUNTIME_E2E=1`),archtest 保证
没人能在不碰 e2e 的情况下把机制拆了(CI 默认面)。

**为什么 run 版本是 +2 而不是 +1**:`version` 由 DB 触发器 `fn_increment_version()`
在**任意** UPDATE 上自增,而成功终态有两次 run 行写入 —— 事务内那次带 CAS 的
`Update`,以及事务外 `SetChargedCredits` 的展示字段回写(刻意不带版本谓词:钱包账本
已是权威,为它让整步失败会触发重投 → 重复结算风险)。用例把 2 钉死,是为了让
"终态路径再多一次 run 行写入"必须有人解释它是谁、为何不需要 CAS。
