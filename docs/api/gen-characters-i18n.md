# 角色(gen_characters)i18n 对接文档

> 生产方:`genaistudio`(Creation BC)· 消费方:客户端 · 变更日:2026-07-22
> migration:`20260722_gen_character_name_i18n.sql`

## 一句话

角色的 `name` / `description` 由**单语言字符串**改为 **i18n 对象** `{"en": "...", "zh": "..."}`(PG jsonb),与 provider `param_schema` 的 label/hint(SduiText 数据源)同构。**后端只产出 `{en,zh}` 两键作唯一数据源;locale 解析、非中英语言翻译、展示全归客户端。**

## 契约变更(破坏性,App 未上线无兼容压力)

| 字段 | 旧 | 新 |
|---|---|---|
| `name` | `"小明"`(string,必填) | `{"en":"Bob","zh":"小明"}`(object,**至少一个非空键**) |
| `description` | `"设定…"`(string) | `{"en":"...","zh":"..."}`(object,可空/`null`) |
| `prompt_anchor` / `negative_anchor` | string | **不变**(模型注入,非展示 i18n) |
| `tags` | string[] | **不变** |

## 受影响端点

| 方法 | 路径 | name/description 形态 |
|---|---|---|
| POST | `/v1/characters` | **请求**:`name`/`description` 传对象 |
| PATCH | `/v1/characters/:bid` | **请求**:同上(`name` 空对象=不改名) |
| GET | `/v1/characters/:bid` | **响应**:`name`/`description` 是对象 |
| GET | `/v1/characters` | **响应**:列表项同上 |

### 请求示例(create / update)

```json
POST /v1/characters
{
  "workspace_bid": "…",
  "name":        { "en": "Bob", "zh": "小明" },
  "description": { "en": "the protagonist", "zh": "少年主角" },
  "kind": "character",
  "asset_bids": ["…"]
}
```
- 单语言用户只传自己那一键即可:`"name": {"zh": "小明"}`。
- 校验:`name` 至少一个非空键(否则 `name: required`);每个语言值 ≤ **128** rune(否则 `name: too_long`)。

### 响应示例(get / list)

```json
{
  "bid": "…",
  "name":        { "en": "Bob", "zh": "小明" },
  "description": { "en": "the protagonist", "zh": "少年主角" },
  "kind": "character",
  "prompt_anchor": "…", "negative_anchor": "…", "tags": ["…"]
}
```

## 客户端职责(后端不做)

1. **按 locale 解析展示**(与现有 `sdui_text.resolve` 同规则):`zh` locale → 取 `zh`;其它所有 locale → 取 `en`;缺 `en` 回退任一非空键。
2. **非中英 19 语言运行时翻译**:从 `en` 值现翻(动态数据无法走构建期 ARB 管线)。
3. **`name` 是专有名词,不要机翻**——直接显示 `en` 值(策展的罗马音/本地化名);只有 `description`(散文)才交给运行时 MT。

## 数据来源约定

- **平台公共角色**(`account_id=0`,全员只读引用):由独立 admin 后台/seed **策展 `{en,zh}` 双键**——这是"供各地区用户使用"的共享库,应补齐 en。
- **用户私有角色**(`account_id>0`):仅创建者可见,客户端按用户当前 locale 传**单键**即可。
- **存量行**:迁移已把旧单语言值包进 `{"zh": ...}`;平台角色 en 译名待 admin 补。

## 说明(非客户端工作,仅告知)

- 后端在**生成 prompt 注入**处(「图片N 是角色『名』」/ 三视图模板)会从 `name` 取单值(优先 `en`,与 `prompt_anchor` 的 en 口径一致)。这是生成内部取值,不影响客户端展示。
- 内部 `register_character` 工具 / admin 单语言入口的写入会包进 `{"zh": ...}`;客户端 resolve 回退保证正确显示。
