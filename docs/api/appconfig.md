# AppConfig BC API 参考

> 设计:`internal/appconfig/api.go`(读侧 1 个公开 HTTP 端点 + 写侧 Module API)
> 模式:`acfg_configs`(平台行,按 `distribution_code` 键控)→ `domain.Resolve`(全局 ∪ 分发 内存合并)
> 客户端协作契约 #8 [P2] — App 远程配置 / kill-switch / 维护态

所有路径前缀 `/v1`。

---

## ⚠️ 与 `/v1/app/init` 的边界(务必先读)

App 启动相关有**两个职责不同、互不重叠**的端点。**严禁把维护/开关塞进 `app/init`,也严禁把 IAP/协议塞进 `app/config`。**

| 端点 | BC | 调用时机 | 下发内容 | 可变性 |
|---|---|---|---|---|
| `POST /v1/app/init` | iap | **启动期一次** | `server_time`(权威时钟)· `update`(版本/强更)· `products`(IAP 商品目录)· `legal`(合规协议链接) | 启动快照 |
| `GET /v1/app/config` | **appconfig(本文)** | 启动 + **运行期轮询** | `maintenance`(维护态)· `kill_switches`(功能熔断)· `config`(远程开关/参数) | **运行期可变** |

设计依据:
- IAP 商品、合规协议、版本更新、服务器时间是**启动期一次性 bootstrap**,归 `app/init`(**既有,不改动**)。
- 维护态 / kill-switch / 远程配置**会在会话中途变化**(运营随时可一键全网维护、关故障功能),必须走**可轮询**的独立通道 `app/config`,否则只有重启 App 才能感知。
- 两端点**字段零重叠**:`app/config` 永不返回 IAP/协议;`app/init` 永不返回 maintenance/kill-switch。

> 客户端建议:启动时各调一次;`app/config` 在前台恢复 / 关键操作前 / 定时(建议 ≥60s)轮询刷新。

---

## 公开端点(App 签名)

### GET /v1/app/config

取当前分发的**有效配置**(全局兜底行 ∪ 当前 `distribution_code` 分发行,服务端内存合并)。

**鉴权**:与 `/v1/app/init` 同属 App 签名公开组(**无需 JWT**)。`distribution_code` 由 App 签名中间件**验签后注入**,客户端**不传**任何 body。

请求头(同所有 `/v1/*` 签名要求,见 [overview.md](overview.md) §5):

| Header | 说明 |
|---|---|
| `X-Distribution-Code` | 分发渠道编码 → 决定取哪个分发行 |
| `X-Timestamp` | Unix 秒(±5min 窗口) |
| `X-Nonce` | UUID v4 防重放 |
| `X-App-Signature` | HMAC-SHA256 hex(64 字符) |

返(`AppConfigDTO`):结构见下「字段」表;**完整真实请求 / 响应抓取**(curl + 实际响应)见下文 [请求 / 响应实例](#请求--响应实例真实抓取server-9999)。

字段:

| 字段 | 类型 | 说明 |
|---|---|---|
| `maintenance.active` | bool | true → 客户端应显示维护页 / 限制进入 |
| `maintenance.message` | string | 维护文案(展示给用户) |
| `maintenance.resume_at` | int64 \| null | 预计恢复时间(**Unix 毫秒 UTC**);null = 未给出 |
| `kill_switches` | string[] | 被熔断的功能 code 列表;客户端应隐藏/禁用对应入口。**恒为数组**(无则 `[]`) |
| `config` | object | 远程开关/参数(键值自由)。**恒为对象**(无则 `{}`) |

> `kill_switches` / `config` 永不为 `null`,客户端可放心直接遍历。

---

## 请求 / 响应实例(真实抓取,server :9999)

> 下列为对本地 dev server **真实发起请求的实际抓取**(`cmd/signtool` 生成签名头 + `curl`,响应为服务端原样返回)。签名头随 `timestamp`/`nonce` 变化(服务端 ±5min 窗口 + nonce 防重放),**直接复制会过期**,用下方命令重新生成。

### 生成签名头(`cmd/signtool`,与服务端 HMAC byte-for-byte 一致)

```bash
go run ./cmd/signtool \
  -secret="<iap_app_distributions.secret_key_hash 的明文 key>" \
  -dist="com.frameink.ai" \
  -headers
# 输出(示例,实际值每次不同):
# X-Distribution-Code: com.frameink.ai
# X-Timestamp: 1781753464
# X-Nonce: cff31558-c660-4c13-9e5c-e4d271c79095
# X-App-Signature: 3f206800fe78360f849799f0d67b40c4834163d2532c604a62e265141a39979d
```

`GET` 无 body → 签名对 `timestamp + nonce + "{}"` 计算(空 body 规整为 `{}`,与中间件一致)。

### 实例 1 — 默认态(当前分发无配置行 → 仅全局兜底)

```bash
curl http://localhost:9999/v1/app/config \
  -H 'X-Distribution-Code: com.frameink.ai' \
  -H 'X-Timestamp: 1781753464' \
  -H 'X-Nonce: cff31558-c660-4c13-9e5c-e4d271c79095' \
  -H 'X-App-Signature: 3f206800fe78360f849799f0d67b40c4834163d2532c604a62e265141a39979d'
```

响应 `200`(原样):

```json
{"code":0,"message":"success","data":{"maintenance":{"active":false,"message":"","resume_at":null},"kill_switches":[],"config":{}},"request_id":"d67d6df9-78fc-4b02-816e-16315270068c","timestamp":1781753464}
```

### 实例 2 — 维护态(运营经 IAM-admin 写入分发行后:维护 + kill-switch + config 合并贯通)

```bash
curl http://localhost:9999/v1/app/config \
  -H 'X-Distribution-Code: com.frameink.ai' \
  -H 'X-Timestamp: 1781753480' \
  -H 'X-Nonce: 65490491-9299-4d91-989d-7231c2646e68' \
  -H 'X-App-Signature: ead6e7a4575a9f66a653ec51f06b61db144963696a9e7b7a14e68cd56a183268'
```

响应 `200`(`data` 美化展示):

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "maintenance": {
      "active": true,
      "message": "系统升级中，预计 30 分钟后恢复",
      "resume_at": 1781755280613
    },
    "kill_switches": ["ai_video_generation", "voice_clone"],
    "config": { "max_upload_mb": 50, "show_new_year_banner": true }
  },
  "request_id": "e7a8981c-1576-4d27-b32e-4b300aedd175",
  "timestamp": 1781753480
}
```

⚠️ **时间戳单位别混用**(此实例为证):`maintenance.resume_at` = **Unix 毫秒**(`1781755280613`),而信封 `timestamp` = **Unix 秒**(`1781753480`)。客户端对 `resume_at` 倒计时应用 `app/init` 下发的 `server_time`(同为毫秒)校时,勿用秒级信封 `timestamp`。

### 实例 3 — 缺签名 → `401`

```bash
curl -i http://localhost:9999/v1/app/config        # 不带任何签名头
```

响应 `401`:

```json
{"code":40110,"message":"missing signature headers: X-Distribution-Code / X-App-Signature / X-Timestamp / X-Nonce"}
```

> 签名头齐全但签名值不匹配 → `40114`(`signature verification failed`);时间戳过窗 / nonce 重放等其余 `401xx` 见 [overview.md](overview.md) §6。

---

## 合并语义(`domain.Resolve`)

客户端拿到的 = **全局兜底行(`distribution_code=''`) ∪ 当前分发行** 合并结果:

1. **维护态**:全局 `active=true` **覆盖一切**(平台级维护,作用所有分发);否则用分发行的维护态。
2. **kill_switches**:全局 ∪ 分发,**去重**(全局优先序,空串滤除)。
3. **config**:全局 ∪ 分发,**分发同名 key 覆盖全局**。

### 事例

| 全局行(`''`) | 分发行(`acme`) | `acme` 客户端最终看到 |
|---|---|---|
| `active=true, msg="全网维护"` | `active=false` | `active=true, msg="全网维护"`(全局覆盖) |
| `active=false` | `active=true, msg="acme 灰度回滚"` | `active=true, msg="acme 灰度回滚"` |
| `kill=[a,b]` | `kill=[b,c]` | `kill=[a,b,c]`(并集去重) |
| `config={x:1,y:2}` | `config={y:3,z:4}` | `config={x:1,y:3,z:4}`(y 被分发覆盖) |

> 运营心智:要「全网维护」→ 写全局行 `''`;要「只停某分发」→ 写该分发行且保持全局 `active=false`。

---

## 客户端集成注意事项

- **fail-open**:服务端在配置库 / 缓存故障时返回**安全默认**(`maintenance.active=false`、空 `kill_switches`、空 `config`),绝不因配置读失败把全网锁在维护页。客户端**无需**对该接口做"失败即拦截"的处理 —— 拿不到就按默认放行。
- **轮询节流**:服务端对配置行有 Redis 缓存(原始行 + 负缓存,TTL 30s),运营写入即时失效;客户端轮询 ≥60s 即可,不必高频。
- **维护态优先级**:`maintenance.active=true` 应优先于 kill_switches / config 处理(直接进维护页)。
- **kill-switch 容错**:遇到**未知**的 kill code 应**安全忽略**(向前兼容,后端可随时新增 code)。
- **config 容错**:缺失的 config key 一律走客户端内置默认值,不可因缺 key 崩溃。
- **时钟**:`resume_at` 是 Unix 毫秒;客户端用 `app/init` 下发的 `server_time` 校正本地时钟后再做倒计时,避免本地时钟漂移。

---

## Module API(写侧 —— 由独立 IAM-admin 项目消费)

本仓**只读对客暴露**;写侧(运营管理)**不提供任何 `/admin` HTTP**(API-Only 定位),只暴露 `AppConfigAPI` 方法,由**独立 IAM-admin 后台**驱动:

```go
type AppConfigAPI interface {
    ResolveAppConfig(ctx, distributionCode string) (*AppConfigDTO, error)   // 读侧(本端点用)
    UpsertAppConfig(ctx, spec *UpsertAppConfigSpec) error                   // 写:全量一行
    SetMaintenance(ctx, distributionCode string, spec *MaintenanceSpec) error // 写:局部维护态
    SetKillSwitches(ctx, distributionCode string, codes []string) error      // 写:整体替换 kill 列表
}
```

写侧契约、集成方式(RPC vs 直写 DB)、RLS / 缓存失效 / version 等**全部不变量**见独立实施 prompt:
**`docs/plan/appconfig-iam-admin-prompt.md`**(可直接交付 IAM-admin 项目)。

---

## 数据模型

| 表 | 主键 / 唯一键 | 说明 |
|---|---|---|
| `acfg_configs` | id;`distribution_code` UNIQUE | 平台行(`tenant_id=0`);`''`=全局兜底,`'X'`=分发 X 覆盖 |

关键列:`maintenance_active` / `maintenance_message` / `maintenance_resume_at`(nullable)/ `kill_switches`(jsonb,存 `[]`)/ `config`(jsonb,存 `{}`)/ `version`(每写 +1)。

迁移:`docs/migrations/p_appconfig_bc_20260617.sql`(建表 + 唯一索引 + RLS + 全局兜底行 seed)。

---

## 安全:RLS

`acfg_configs` 启用 RLS + FORCE,POLICY `acfg_configs_tenant_isolation`(NULLIF-hardened):
- **USING(读)**:`tenant_id=0` 全可读 + 本租户行 + GUC 未设置(公开读路径放行)。
- **WITH CHECK(写)**:本租户行 + GUC 未设置;**不含 `OR tenant_id=0`** → 任何绑定租户 GUC 的会话**都无法伪造平台行**(防恶意租户注入全局 kill-switch / 伪造维护态 DoS 全网)。

启动期 `schemaassert` 校验该 POLICY 存在性(缺失则 fail-fast 拒绝启动)。

---

## 错误处理

读侧 **fail-open**,正常情况下恒返 `code=0`(信封见 [overview.md](overview.md) §3):
- 配置库/缓存故障 → 返安全默认配置(非错误码)。
- App 签名校验失败 → 由中间件统一返 `401xx`(与本 BC 无关):缺签名头 `40110`、签名不匹配 `40114`、时间戳过窗 / nonce 重放等见 [overview.md](overview.md) §6。真实抓取见上 [§请求 / 响应实例 实例 3](#实例-3--缺签名--401)。

本 BC **不定义** `4xxxx/5xxxx` 业务错误码(读路径无业务失败分支)。

---

## OpenAPI 3.1 Specification

> 来源:`internal/appconfig/port/http/{routes,config_handler}.go` + `appconfig/api.go::AppConfigAPI.ResolveAppConfig`。读侧**仅 1 个公开 HTTP 端点**;写侧走 Module API,不暴露 HTTP。公共契约见 [overview.md](overview.md)。

```yaml
openapi: 3.1.0
info:
  title: AIGC Platform — AppConfig Domain API
  description: |
    AppConfig BC 1 个公开 HTTP 端点:
      - GET /v1/app/config 取当前分发的有效远程配置(维护态 / kill-switch / 远程开关)

    写侧(Upsert / SetMaintenance / SetKillSwitches)走 Module API (AppConfigAPI),
    由独立 IAM-admin 项目消费, 不暴露 HTTP (API-Only 定位)。

    与 POST /v1/app/init (iap BC) 职责不重叠: init 下发 IAP 商品 / 合规协议 /
    版本更新 / server_time (启动快照); config 下发维护 / kill-switch / 远程配置 (运行期可轮询)。
  version: "1.0.0"

servers:
  - url: https://api.aigc.example.com/v1
  - url: http://localhost:9999/v1

# 公开端点: 仅 App 签名 (无 JWT)
security:
  - DistributionCode: []
    Timestamp: []
    Nonce: []
    AppSignature: []

components:
  securitySchemes:
    DistributionCode: { type: apiKey, in: header, name: X-Distribution-Code }
    Timestamp: { type: apiKey, in: header, name: X-Timestamp }
    Nonce: { type: apiKey, in: header, name: X-Nonce }
    AppSignature: { type: apiKey, in: header, name: X-App-Signature }

  schemas:
    StandardResponse:
      type: object
      required: [code, message, request_id, timestamp]
      properties:
        code: { type: integer, example: 0 }
        message: { type: string }
        data: {}
        request_id: { type: string, format: uuid }
        timestamp: { type: integer, format: int64 }

    Maintenance:
      type: object
      required: [active, message]
      properties:
        active: { type: boolean, description: true → 客户端应进入维护页 }
        message: { type: string, description: 维护文案 }
        resume_at:
          type: integer
          format: int64
          nullable: true
          description: 预计恢复时间 (Unix 毫秒 UTC); null = 未知

    AppConfig:
      type: object
      required: [maintenance, kill_switches, config]
      properties:
        maintenance: { $ref: '#/components/schemas/Maintenance' }
        kill_switches:
          type: array
          description: 被熔断的功能 code (恒为数组, 无则 []); 客户端隐藏/禁用对应入口, 未知 code 应安全忽略
          items: { type: string }
        config:
          type: object
          description: 远程开关/参数 (恒为对象, 无则 {}); 缺失 key 走客户端默认值
          additionalProperties: true

paths:
  /app/config:
    get:
      summary: 取当前分发的有效远程配置 (维护 / kill-switch / config)
      operationId: getAppConfig
      tags: [AppConfig]
      description: |
        distribution_code 由 App 签名中间件验签注入 (客户端不传 body)。
        响应 = 全局兜底行 ∪ 当前分发行 内存合并 (见 domain.Resolve)。
        **fail-open**: 配置库/缓存故障返安全默认 (维护关 / 空集合), 恒 code=0。
      responses:
        '200':
          description: 有效配置
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/AppConfig' }
        '401':
          description: App 签名校验失败 (401xx, 见 overview.md §6)

# 错误码段
# 读侧 fail-open, 无业务错误码; 签名失败由中间件统一返 401xx.
# code=0 success (信封见 overview.md §3)。
```

---

## 关联文档

- 端点总览:[endpoint-inventory.md](endpoint-inventory.md) §AppConfig BC
- IAM-admin 写侧实施 prompt:`docs/plan/appconfig-iam-admin-prompt.md`
- 迁移:`docs/migrations/p_appconfig_bc_20260617.sql`
