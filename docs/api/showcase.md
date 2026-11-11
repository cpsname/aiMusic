# Showcase 灵感库 HTTP API(对接文档)

> **Module**: `internal/catalog/showcase/port/http`  ·  路径前缀 `/v1/showcases` · `/v1/showcase-categories` · `/v1/showcase-tags`
>
> **定位**:Showcase 灵感库是 Catalog BC 的 `cat_*` 扩展 —— 面向**终端用户的发现端**:浏览 / 检索 / 详情 / 分类 / 标签 + "制作同款"。
> 本仓库**只实现发现端(只读)**;灵感内容的运营管理(创建 / 上下架 / 归档)由**独立运营后台**承担(后台 / 接口分离)。
>
> **Sources of truth**:
> - 路由:`internal/catalog/showcase/port/http/routes.go`
> - DTO:`internal/catalog/showcase/port/http/dto.go`
> - 错误码映射:`internal/catalog/showcase/port/http/errors.go`(`mapDomainErr`,47000–47099)
> - 数据库 DDL:`docs/migrations/p8_06_showcase_catalog.sql`(9 表 + RLS + 种子)
> - 通用机制(BaseURL / 中间件 / Envelope):[overview.md](overview.md)

---

## 一、对接快速上手

| 项 | 值 |
|---|---|
| 开发 BaseURL | `http://localhost:9999/v1` |
| 生产 BaseURL | `https://api.aigc.example.com/v1` |
| 鉴权 | 发现端 5 个端点为 **public 路由**,**无需 JWT**(匿名可浏览)。App 签名等平台级中间件按 `/v1/*` 全局链要求,详见 [overview.md §2](overview.md) |
| 响应 Envelope | `{ "code": 0, "message": "...", "data": {...}, "request_id": "...", "timestamp": ... }`,`code == 0` 为成功 |
| 内容范围 | 仅返回**已上架(`published`)的平台内容**;草稿 / 下架 / 归档对发现端不可见 |
| 多语言 | 所有列表 / 详情 / 分类 / 标签接口支持 `lang` 查询参数,缺省 `zh-CN`(服务端归一化为 `zh`);**客户端按设备 locale 原样透传即可**,见下方提示 |

> **📢 多语言透传提示(2026-07-10)**:后端已做**全量多语言,取消收敛** —— 客户端把 `lang` 按**设备 locale 原样透传**(BCP-47 / iOS 三段式均可),**不再折叠到 `en`**,由服务端 `resolveLang` 统一归一化(实现:`internal/catalog/showcase/app/query/query_support.go`):
>
> - **中文区分简繁**:`zh-Hans` / `zh-Hans-CN` / `zh-CN` / `zh-SG` → `zh`(简体);`zh-Hant` / `zh-Hant-TW` / `zh-TW` / `zh-HK` / `zh-MO` → `zh-Hant`(繁体)
> - 其余语言截主码:`en-US` → `en`、`pt-BR` → `pt`、`es-419` → `es`、`fr-CA` → `fr` …
> - i18n 语料全量 **15 语言**:`zh` · `zh-Hant` · `en` · `de` · `es` · `fr` · `it` · `ja` · `ko` · `pt` · `ru` · `sv` · `th` · `tr` · `vi`
> - `lang` 缺省 / 空串 → `zh`

---

## 二、路由总览(5 endpoints,全部 `GET`)

| Method | Path | 用途 | 鉴权 | 可能错误码 |
|---|---|---|---|---|
| `GET` | `/v1/showcases` | 发现灵感:多维筛选 + **全文检索** + 分页 | 匿名 | 47013 |
| `GET` | `/v1/showcases/search` | **DEPRECATED** — 兼容老客户端,内部转发 `/v1/showcases?q=...`;响应附 `Deprecation: true` + `Link: </v1/showcases>; rel="successor-version"` header。新客户端请改用 `/v1/showcases?q=...` | 匿名 | — |
| `GET` | `/v1/showcases/:bid` | 灵感详情(含 i18n + stats + presets);顺带浏览数 +1 | 匿名 | 47001 / 47013 |
| `GET` | `/v1/showcase-categories` | 分类 Tab 树(两级) | 匿名 | — |
| `GET` | `/v1/showcase-tags` | 筛选面板标签(按分组) | 匿名 | — |

> **关于 `/search` 端点的归并**:2026-05-27 起,关键词检索作为 `/v1/showcases` 的一个普通过滤维度(参数名 `q`),可与 `category` / `tag_ids` / `sort` / 分页**任意组合**(例:`?q=人像&category=photography&sort=hot&page=2`)。这是底层 `ShowcaseRepository.List(filter)` 早就支持的能力,旧切分仅来自 app/HTTP 层的人为划分。`/v1/showcases/search` 作为 deprecated 别名保留以避免破坏老客户端,内部转发到同一处理器。

---

## 三、关键概念

### 3.1 媒体类型 / 难度 / 状态枚举

| 字段 | 取值 |
|---|---|
| `media_type` | `image` · `video` · `audio` · `text` · `multimodal` · `code` |
| `difficulty` | `beginner`(一键生成)· `intermediate`(需基础提示词)· `expert`(多参数 / LoRA) |
| `status` | `draft` · `published` · `unpublished` · `archived`(发现端只会看到 `published`) |
| `region_scope` | `global` · `cn` · `eu` · `us` · `asia` |
| `compliance_level` | `general` · `restricted` · `sensitive` |

### 3.2 标签分组(`tag_group`)

筛选面板按 `tag_group` 分区渲染:`model_type`(模型类型)· `scene`(使用场景)· `style`(风格)· `feature`(功能特性,如"无提示词 / 商用许可")· `model_ref`(具体模型引用)· `custom`(自定义)。

### 3.3 "制作同款"创作预设(`primary_preset` / `presets`)

每个灵感关联若干创作预设。`role = primary` 的主预设用于"一键制作同款":客户端拿到 `model_version_bid` + `preset_params`,跳转到 Creation BC `POST /v1/tasks`,以 `version_bid` + 预填 `input_params` 发起创作(用户可覆写参数)。

**`role = workflow_primary`(FT-6,旗舰 Workflow 模板卡)**:预设绑 `agent_bid`(非模型),"制作同款" 跳 `POST /v1/conversations`(`agent_bid`,`workspace_bid` 可空走个人空间)→ `POST .../messages`(`variables` = preset_params 预填,表单 schema 从 Agent 详情 `definition.input_schema` 渲染)。引用目标 XOR(`model_version_bid` ⊕ `agent_bid`,DB CHECK + 域校验);一张卡同款入口唯一(primary 与 workflow_primary 互斥,partial unique)。`is_premium=true` 的模板卡对应 Agent 声明 `feature_flags.required_feature="member"`,SendMessage 无权益返 **40303**(端侧引导订阅)。类目 `entity_type='workflow_template'` / code `flagship`;cover/preview 由试产成片回填(独立 admin 后台)。

### 3.4 统计计数(`stats`)

浏览 / 点赞 / 收藏 / 制作同款数等。`GET /v1/showcases/:bid` 详情接口会**异步把 `view_count` +1**(Redis 聚合,后台 worker 周期 flush 入库,最终一致)。`heat_score` 热度分 = 浏览×0.1 + 制作×3 + 点赞×1。

---

## 四、端点契约

### 4.1 `GET /v1/showcases` — 发现灵感列表(+ 全文检索)

**Query 参数**(全部可选,任意组合):

| 参数 | 类型 | 说明 |
|---|---|---|
| `q` | string | 全文关键词;命中 i18n `search_vector`(`name + short_desc + prompt`);**与下方所有过滤维度可任意组合** |
| `category` | string | 分类编码(`category_code`),如 `photography` |
| `media_type` | string | 媒体类型过滤 |
| `is_premium` | bool | `true`/`false` — 会员专属过滤 |
| `is_hot` | bool | 热门过滤 |
| `tag_ids` | string | 逗号分隔的标签 id,如 `12,18`;过滤语义由 `tag_match` 控制 |
| `tag_match` | string | `all`(缺省,**AND** —— 须同时含全部) \| `any`(**OR** —— 任一命中即可,筛选面板交互友好) |
| `meta` | string | JSONB 高级过滤,URL-encoded JSON,如 `{"commercial_use":true}` |
| `published_within_days` | int | 仅返回近 N 天上架,如 `7` / `30` |
| `sort` | string | 排序模式,见下方说明 |
| `lang` | string | i18n 语言,缺省 `zh-CN`(当 `q` 非空时同时决定 tsvector 词典 / 词形) |
| `page` | int | 页码,1 起,缺省 `1` |
| `page_size` | int | 每页条数,缺省 `20`,**上限 `50`** |

**`sort` 取值与缺省策略**:

| `sort` | 排序依据 | 备注 |
|---|---|---|
| `hot` | `cat_showcase_stats.heat_score DESC` | 跨表 `LEFT JOIN`,允许与 `q` 同时使用 |
| `new` | `published_at DESC NULLS LAST` | — |
| `relevance` | `ts_rank(search_vector) DESC` | **必须**配合 `q`;无 `q` 时自动退化为 `sort_order` |
| `sort_order`(或不传 & 无 `q`) | `sort_order DESC` | 运营人工排序权重 |
| **不传 & 有 `q`** | `relevance` 退化 | 关键词存在时默认按相关度 |

**响应** `data`:

```json
{
  "items": [
    {
      "bid": "0f9c…",
      "cover_url": "https://r2/cover.png",
      "preview_url": "https://r2/preview.mp4",
      "ratio": "16:9",
      "cover_width": 1920,
      "cover_height": 1080,
      "media_type": "image",
      "category_code": "photography",
      "difficulty": "beginner",
      "credits_cost": 0,
      "is_premium": false,
      "is_hot": true,
      "published_at": "2026-05-18T10:00:00Z",
      "name": "真实感人像写真",
      "short_desc": "一键生成影棚级人像",
      "view_count": 12030,
      "use_count": 860,
      "like_count": 2104,
      "heat_score": 5821.5,
      "primary_preset": {
        "model_version_bid": "a1b2…",
        "provider_code": "volcengine",
        "role": "primary",
        "badge_label": "无需提示词",
        "preset_params": { "aspect_ratio": "3:4" },
        "sort_order": 0
      },
      "tags": [
        { "bid": "11ee…", "code": "realistic", "tag_group": "style",   "name": "写实" },
        { "bid": "22ff…", "code": "portrait",  "tag_group": "scene",   "name": "人像" }
      ]
    }
  ],
  "total": 137,
  "page": 1,
  "page_size": 20
}
```

- `primary_preset` 可能为 `null`(灵感未配置主预设)。
- `tags`:卡片 chip 渲染数据,已按 `sort_order DESC, id ASC` 排序;无关联标签时字段省略(`omitempty`)。后端**单次批量** SQL 取齐当前页全部 showcase 的 tag(无 N+1),客户端无需自行 join `/v1/showcase-tags` 字典。

### 4.2 `GET /v1/showcases/search` — **DEPRECATED** 全文检索(兼容别名)

> **状态**:2026-05-27 起标记 deprecated。**响应头**:
> ```
> Deprecation: true
> Link: </v1/showcases>; rel="successor-version"
> ```
> 推荐切换到 `/v1/showcases?q=...` —— 同 endpoint 支持关键词 + 全部过滤维度 + 分页 + 自定义排序;**响应 shape 更完整**(含 `total` / `page` / `page_size`)。

**保留原因**:不破坏既有 iOS/Android/Web SDK 的调用契约。本端点内部转发到与 4.1 同一处理器(`ListShowcasesHandler`),底层逻辑完全一致。

**Query 参数**(保留旧契约):`q`(空则返回空列表)· `lang`(缺省 `zh-CN`)· `limit`(缺省 `20`,上限 `50`)。

**响应** `data`(旧 shape):`{ "items": [ /* 同 4.1 的列表项 */ ] }`(无 `total` / 无分页)。

**已删除的差异**:旧版的关键词检索**忽略**所有维度过滤(`category` / `tag_ids` / `sort` 等),且固定按 `ts_rank` 排序;现统一到 4.1 后所有维度可叠加。

### 4.3 `GET /v1/showcases/:bid` — 灵感详情

`:bid` 为灵感的 UUID。**Query 参数**:`lang`(缺省 `zh-CN`)。

> 副作用:成功返回时异步把该灵感 `view_count` +1。

**响应** `data`:

```json
{
  "bid": "0f9c…",
  "category_id": 3,
  "category_code": "photography",
  "media_type": "image",
  "cover_url": "https://r2/cover.png",
  "preview_url": "https://r2/preview.mp4",
  "ratio": "16:9",
  "cover_width": 1920,
  "cover_height": 1080,
  "difficulty": "beginner",
  "credits_cost": 0,
  "is_premium": false,
  "is_hot": true,
  "is_featured": false,
  "region_scope": "global",
  "compliance_level": "general",
  "status": "published",
  "published_at": "2026-05-18T10:00:00Z",
  "name": "真实感人像写真",
  "short_desc": "一键生成影棚级人像",
  "prompt": "studio portrait, soft light, 85mm",
  "negative_prompt": "blurry, lowres",
  "stats": {
    "view_count": 12031, "like_count": 2104, "collect_count": 530,
    "use_count": 860, "share_count": 77, "comment_count": 12, "heat_score": 5821.5
  },
  "presets": [
    {
      "model_version_bid": "a1b2…", "model_bid": "c3d4…", "provider_code": "volcengine",
      "role": "primary", "badge_label": "无需提示词",
      "preset_params": { "aspect_ratio": "3:4", "seed": 42 }, "sort_order": 0
    }
  ],
  "tags": [
    { "bid": "11ee…", "code": "realistic", "tag_group": "style", "name": "写实" },
    { "bid": "22ff…", "code": "portrait",  "tag_group": "scene", "name": "人像" }
  ]
}
```

- 灵感不存在或非 `published` → `code 47001`(发现端不泄露草稿存在性)。
- `:bid` 非法 UUID → `code 47013`。
- **`tags`**(发现端 chip):字段顺序 `sort_order DESC, id ASC`,已剔除 `is_active=false` 的停用标签;`omitempty`。后端单次批量取齐(无 N+1),客户端**无需**额外打 `/v1/showcase-tags` 字典 hydrate。
- 管理端额外字段(本文档不展开):返回 `tag_ids: [int64,...]`(raw id 数组,供表单回显)+ 全语言 `i18n[]`,通过独立运营后台调用,不在此 API。

### 4.4 `GET /v1/showcase-categories` — 分类树

**Query 参数**:`entity_type`(缺省 `showcase`)· `lang`(缺省 `zh-CN`)。

**响应** `data`(两级树形数组):

```json
[
  {
    "bid": "…", "code": "photography", "name": "摄影写真",
    "description": "真实感人像、风景、产品摄影模板",
    "sort_order": 100, "meta": { "icon_url": "/icons/cat/photography.svg" },
    "children": [
      { "bid": "…", "code": "portrait", "name": "人像写真", "description": "",
        "sort_order": 10, "meta": {}, "children": [] }
    ]
  }
]
```

### 4.5 `GET /v1/showcase-tags` — 标签字典(筛选面板 / id 反查 hydrate)

**Query 参数**(全部可选,任意组合):

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `entity_type` | string | `showcase` | 资源类型鉴别器 |
| `lang` | string | `zh-CN` | i18n 语言 |
| `tag_group` | string | — | 单组过滤,值必须 in [`model_type`,`scene`,`style`,`feature`,`model_ref`,`custom`];非法值 400 |
| `ids` | string | — | 逗号分隔 id 集合,进入 lookup 模式(用于"已选标签 chip hydrate"场景:客户端只缓存了 id 数组,要回填 name + group 时调用) |
| `non_empty` | bool | `false` | `true` 仅返实际挂在 `entity_type` 资源上的 tag(排除运营建好但**还没打到任何灵感**的孤儿标签,避免用户点击后空结果) |

**双模式**:
- **筛选面板**(无 `ids`):按 `tag_group` 分区返回全部启用 tag,作为左侧筛选侧栏数据源
- **lookup**(传 `ids`):按 id 集合精确取,仍按 `tag_group` 分区,常用于"已勾选 chip"hydrate

**响应** `data`(按 `tag_group` 分区,稳定顺序 `model_type → scene → style → feature → model_ref → custom`,空分组省略):

```json
[
  {
    "group": "model_type",
    "tags": [
      { "bid": "…", "code": "lora", "tag_group": "model_type", "name": "LoRA",
        "model_version_bid": "", "sort_order": 90, "meta": {} }
    ]
  },
  {
    "group": "feature",
    "tags": [
      { "bid": "…", "code": "commercial_use", "tag_group": "feature", "name": "商用许可",
        "model_version_bid": "", "sort_order": 90, "meta": { "badge": "商用许可" } }
    ]
  }
]
```

`model_version_bid` 仅 `tag_group = model_ref` 的标签非空。

---

## 五、curl 示例

```bash
BASE=http://localhost:9999/v1

# 列表:摄影分类 + 热门 + 按热度排序 + 第 2 页
curl "$BASE/showcases?category=photography&is_hot=true&sort=hot&page=2&page_size=20"

# 多标签 AND 过滤 — 须同时含标签 12 与 18 (缺省语义)
curl "$BASE/showcases?tag_ids=12,18&lang=en"

# 多标签 OR 过滤 — 含 12 或 18 任一即可 (筛选面板交互友好)
curl "$BASE/showcases?tag_ids=12,18&tag_match=any&lang=en"

# meta 高级过滤(商用许可)
curl "$BASE/showcases?meta=%7B%22commercial_use%22%3Atrue%7D"

# 全文检索(推荐):支持与所有过滤维度叠加
curl "$BASE/showcases?q=人像写真&lang=zh-CN&page_size=10"

# 关键词 + 分类 + 排序按热度(老 /search 端点做不到)
curl "$BASE/showcases?q=人像&category=photography&sort=hot&page=1&page_size=20"

# DEPRECATED 兼容别名(响应附 Deprecation header)
curl -i "$BASE/showcases/search?q=人像写真&limit=10"

# 详情
curl "$BASE/showcases/0f9c0000-0000-0000-0000-000000000000?lang=zh-CN"

# 分类树
curl "$BASE/showcase-categories"

# 全量标签面板 (按 group 分区)
curl "$BASE/showcase-tags?lang=en"

# 只取 style 一组 (前端按 group 异步加载)
curl "$BASE/showcase-tags?tag_group=style&lang=en"

# 仅返实际挂在灵感上的 tag (排除孤儿标签, 避免用户点了空结果)
curl "$BASE/showcase-tags?non_empty=true&lang=en"

# Lookup 模式 — 客户端只缓存了 id 数组, hydrate 回 name + group 用于 chip 渲染
curl "$BASE/showcase-tags?ids=12,18,33&lang=zh-CN"
```

---

## 六、错误码段(47000–47099)

发现端只读,实际可命中 **47001 / 47013**;其余为 Showcase BC 写路径(由独立运营后台触发)的领域错误,一并列出供完整参考。

| 码 | HTTP 语义 | 含义 | 发现端可命中 |
|---|---|---|---|
| 47001 | 404 | showcase not found(不存在或非 published) | ✓ |
| 47002 | 404 | category not found | |
| 47003 | 404 | tag not found | |
| 47004 | 409 | showcase archived, not writable | |
| 47005 | 409 | invalid showcase status transition | |
| 47006 | 409 | version conflict(乐观锁) | |
| 47007 | 409 | more than one primary preset | |
| 47008 | 400 | invalid preset params | |
| 47009 | 400 | tag entity_type mismatch | |
| 47010 | 400 | duplicate i18n lang | |
| 47011 | 400 | at least one i18n entry required | |
| 47012 | 400 | preset model_version_bid required | |
| 47013 | 400 | invalid parameter(如非法 `:bid`) | ✓ |
| 47301 | 403 | permission denied | |

错误响应示例:

```json
{ "code": 47001, "message": "showcase not found", "data": null,
  "request_id": "…", "timestamp": 1747900000 }
```

---

## 七、对接备注

- **只读发现端**:本仓库 showcase 仅 5 个 `GET` 端点。灵感的创建 / 编辑 / 上下架 / 归档由独立运营后台负责,**不在本 API**。
- **可见性**:列表 / 搜索 / 详情一律只返回平台 `published` 内容;`GET /:bid` 对草稿 / 下架灵感返回 `47001`。
- **分页上限**:`page_size` 与 `search` 的 `limit` 硬上限 `50`,超出自动截断。
- **多语言透传(取消收敛)**:后端全量 15 语言,客户端 `lang` 按设备 locale 原样透传(中文区分简繁:`zh-Hans*`→简体 / `zh-Hant*`·`zh-TW`·`zh-HK`→繁体),**不要再在端侧折叠到 `en`**;归一化由服务端负责(见 §一 提示)。
- **多语言回退**:`lang` 缺省 / 无对应语言语料时,`name`/`short_desc` 可能为空串;客户端需做兜底。
- **制作同款链路**:取 `primary_preset.model_version_bid` + `preset_params` → 跳转 Creation BC `POST /v1/tasks`(契约见 [creation.md](creation.md))。
- **统计最终一致**:`view_count` 等经 Redis 聚合 + 后台周期 flush,详情接口读到的计数可能略滞后于真实值。
