# Knowledge BC API 参考

> 设计:`docs/architecture/knowledge/module-design.md`(完整) + `docs/architecture/knowledge/pre-analysis.md`(Step 0 跨厂商对照)
> 实装:`internal/knowledge/api.go` + `port/http/`

所有路径前缀 `/v1`,全 JWT 鉴权。

## 知识库 CRUD

### POST /v1/knowledge/bases
创建 KnowledgeBase。

```json
{
  "name": "Product Docs",
  "description": "产品文档库",
  "provider_id": 3,                  // prov_providers.id (Google AI / 火山等)
  "channel_id": 7,                   // prov_provider_channels.id
  "model_version_id": 12,            // prov_model_versions.id (embedding 模型)
  "config": {
    "chunking_policy": {
      "strategy": "fixed",            // fixed / sentence / paragraph
      "chunk_size": 512,
      "chunk_overlap": 50
    },
    "metadata_schema": {
      "fields": [
        { "name": "category", "type": "string", "required": false }
      ]
    },
    "default_top_k": 5
  }
}
```

返(`KnowledgeBaseDTO`):
```json
{
  "kb_id": 100,
  "bid": "uuid",
  "tenant_id": 1,
  "owner_account_id": 456,
  "name": "Product Docs",
  "provider_id": 3,
  "channel_id": 7,
  "model_version_id": 12,
  "upstream_store_id": "fileSearchStores/abc",  // Gemini 返回; 异步创建后回填
  "status": "active",
  "config": { ... },
  "stats": {
    "document_count": 0,
    "active_document_count": 0,
    "total_size_bytes": 0
  },
  "created_at": "..."
}
```

行为:
- 配额校验(三层 default → tenant → account → kb)
- 调对应 provider adapter `CreateStore`(Gemini FileSearchStores SDK)
- `upstream_store_id` 回填后 status=active
- Outbox `knowledge.knowledge_base_created`

### GET /v1/knowledge/bases
列 KB。Query:`status` / `limit` / `offset`。

### GET /v1/knowledge/bases/:bid
取 KB 详情(含 stats)。

### DELETE /v1/knowledge/bases/:bid
软删 KB。状态机 `active → archived → deleting`。

行为:
- 阻塞:含 active documents 时拒绝(需先批量删 doc)
- archived 状态保留可读不可写;删除后异步触发 upstream store 删除
- Outbox `knowledge.knowledge_base_archived`

### UpdateKB(未实装)

`PATCH /v1/knowledge/bases/:bid` 路由未注册。`api_local.go::UpdateKB` 返 `ErrCapabilityUnsupported`。可变字段(name/description/config)更新留首版后。

## 文档管理

### POST /v1/knowledge/bases/:bid/documents
上传文档。3 种来源:

```json
{
  "source": {
    "kind": "inline_upload",          // inline_upload / asset_ref / url
    "filename": "manual.pdf",
    "content_base64": "...",          // inline 用
    "content_type": "application/pdf"
  },
  "custom_metadata": {
    "category": "user_guide",
    "version": "1.0"
  }
}
```

或 asset 引用:
```json
{
  "source": {
    "kind": "asset_ref",
    "asset_bid": "..."                // gen_assets.bid
  }
}
```

或 URL:
```json
{
  "source": {
    "kind": "url",
    "url": "https://example.com/manual.pdf"
  }
}
```

返(`DocumentDTO`):
```json
{
  "document_id": 200,
  "bid": "uuid",
  "kb_id": 100,
  "filename": "manual.pdf",
  "size_bytes": 102400,
  "state": "queued",                  // queued → ingesting → active / failed → deleting
  "custom_metadata": { ... },
  "upstream_doc_id": "",               // 异步回填
  "ingestion_op_id": "...",            // 异步 Op 追踪 (rt_workflow 风格)
  "created_at": "..."
}
```

行为:
- `metadata_schema` 校验 `custom_metadata`
- 落 `kb_documents` + `kb_document_operations`(state=pending,异步)
- `IngestPollWorker` 轮询 op 状态(指数退避)
- active 后 Outbox `knowledge.document_activated`;failed `knowledge.document_failed`

### GET /v1/knowledge/bases/:bid/documents
列文档。Query:`state` / `limit` / `offset` / `metadata_filter`。

### GET /v1/knowledge/bases/:bid/documents/:doc_bid
取文档详情。

### DELETE /v1/knowledge/bases/:bid/documents/:doc_bid
软删 doc。状态机 `active → deleting`。异步删 upstream store doc。

## 检索 + 生成

### POST /v1/knowledge/bases/:bid/retrieve
语义检索。

```json
{
  "question": "如何开通 VIP?",
  "top_k": 5,
  "metadata_filter": {                 // 可选,前端 JSON 表达式
    "category": "user_guide"
  },
  "rerank_strategy": "default"         // 可选,部分厂商支持
}
```

返(`RetrieveResult`):
```json
{
  "chunks": [
    {
      "text": "...",
      "score": 0.92,
      "document_bid": "...",
      "document_title": "manual.pdf",
      "uri": "...",
      "first_page": 12,
      "last_page": 14,
      "metadata": { "category": "user_guide" }
    }
  ],
  "citations": [ { ... } ],            // 引用元数据
  "usage_tokens": 150,
  "latency_ms": 230,
  "used_kb_bids": ["..."]
}
```

跨 KB 检索(Capability 支持时):body 改 `kb_bids: ["uuid1", "uuid2"]`(走多 store 入口)。

### POST /v1/knowledge/bases/:bid/generate
检索 + 生成一步完成(GroundedGenerate)。

```json
{
  "question": "...",
  "top_k": 5,
  "model_code": "gemini-2.5-flash",
  "vendor_extras": { ... }
}
```

返:
```json
{
  "answer": "根据知识库...",
  "citations": [ { ... } ],
  "chunks_used": [ ... ],
  "usage_tokens": 1200,
  "latency_ms": 850
}
```

Capability 不支持时返 `ErrCapabilityUnsupported`(40090)— 仅 Gemini 首版支持。

## Module API(跨 BC)

`knowledge.KnowledgeAPI` 暴露给 Catalog Workflow `retrieval` 节点 + 未来 Agent 引用 KB:

```go
Retrieve(ctx, *RetrieveCmd) (*RetrieveResult, error)
GroundedGenerate(ctx, *GroundedGenerateCmd) (*GroundedGenerateResult, error)

// 跨模块协作
ResolveStoreHandles(ctx, accountID, kbBIDs) ([]StoreHandle, error)
CheckAccess(ctx, accountID, kbBIDs) error
```

`runtimeKnowledgePortBridge`(P4-01 Phase F.1)适配 `Retrieve` → Workflow `retrieval` 节点。

## Provider Capability 矩阵

每 Provider Adapter(`internal/knowledge/infra/gateway/adapters/<vendor>/`)声明 13 位 Capability:

| Capability | Gemini | Bailian | Doubao |
|---|---|---|---|
| SupportsCreateStore | ✅ | (占位) | (占位) |
| SupportsAsyncIngest | ✅ | | |
| SupportsRetrieve | ✅ | | |
| SupportsGroundedGenerate | ✅ | | |
| SupportsMetadataFilter | ✅ | | |
| SupportsMultiStoreQuery | ✅ | | |
| SupportsRerank | ✅ | | |
| SupportsRewrite | ✅ | | |
| SupportsPageSpan | ✅ | | |
| ... | | | |

> Bailian / Doubao 当前是骨架(`bailian/adapter.go` 全返 `ErrCapabilityUnsupported`)。接入前需完整阅读 SDK,详见 `docs/architecture/knowledge/pre-analysis.md` §4.2。

## 数据模型

| 表 | 主键 | 说明 |
|---|---|---|
| `kb_knowledge_bases` | id, bid | 聚合根;状态机 active → archived → deleting;持 provider/channel/model 软引用 + upstream_store_id |
| `kb_documents` | id | doc 实体;状态机 queued → ingesting → active/failed → deleting |
| `kb_document_operations` | id | 异步 Op 追踪;Worker 扫 `state='pending' AND next_poll_at <= now()` FOR UPDATE SKIP LOCKED |
| `kb_quotas` | id | 三层 scope quota(default → tenant → account → kb) |

Free Tier 默认配额(`kb_quotas`): 5 KB / 500 doc / 300 MiB / 100 MB 单文件。

## Outbox 事件清单(6 种)

`internal/knowledge/app/events/`:
- `knowledge.knowledge_base_created` / `_archived`
- `knowledge.document_submitted` / `_activated` / `_failed`

## 凭证管理

**当前(dev MVP)**:Gemini ClientFactory 走 `os.Getenv("GEMINI_API_KEY")`,**不走** Provider BC 通道凭证解密。

**生产前必须改**:按 `channel_id` 解密 `prov_provider_channels.credential_cipher`。详见 CLAUDE.md "Knowledge Gemini ClientFactory 走 env" KTD。

## 限制与起跳点

- `UpdateKB` 未实装(name/desc/config 不可改)
- Bailian / Doubao Adapter 未真接入(占位)
- FileSearchStores 仅 Gemini AI Studio 后端(Vertex AI 不支持)
- `knowledgeProviderAccessor.ResolveModelVersion` 桥占位(硬编码 providerID → providerCode 映射,详见 CLAUDE.md KTD)

## 错误码段

- `40090` Capability Unsupported(adapter 不支持的方法)
- `40410` KB / Document 不存在
- `40903` 配额超限
- `40020` metadata_schema 校验失败

详见 `internal/knowledge/domain/errors.go`。

## OpenAPI 3.1 Specification

> 基于代码事实生成。来源:`internal/knowledge/port/http/{routes,kb_handler,document_handler,query_handler}.go` + `api.go` + `domain/{errors,valueobject/{kb_state,doc_state,source_type,chunking_policy,metadata_schema}}.go`。
>
> 公共契约见 [overview.md](overview.md)。多厂商 RAG (首版 Gemini FileSearchStores,bailian/doubao 占位)。

```yaml
openapi: 3.1.0
info:
  title: AIGC Platform — Knowledge Domain API
  description: |
    Knowledge BC 10 endpoints:
      - KB CRUD: 4 endpoints
      - Document 三种来源 (inline_upload / asset_ref / url): 4 endpoints
      - Retrieve / GroundedGenerate: 2 endpoints
  version: "1.0.0"

servers:
  - url: https://api.aigc.example.com/v1
  - url: http://localhost:9999/v1

security:
  - BearerAuth: []
    DistributionCode: []
    Timestamp: []
    Nonce: []
    AppSignature: []

components:
  securitySchemes:
    BearerAuth: { type: http, scheme: bearer, bearerFormat: JWT }
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

    ChunkingPolicy:
      type: object
      properties:
        strategy:
          type: string
          enum: [whitespace, sentence, paragraph, semantic]
        max_tokens_per_chunk: { type: integer, minimum: 1, default: 500 }
        overlap_tokens: { type: integer, minimum: 0, default: 80, description: "必须 < max_tokens_per_chunk" }
        extras:
          type: object
          additionalProperties: true
          description: 厂商专属扩展

    MetadataSchemaEntry:
      type: object
      required: [key, type]
      properties:
        key: { type: string, description: "不重复, 不可下划线开头" }
        type: { type: string, enum: [string, number, string_list] }
        required: { type: boolean }
        filterable: { type: boolean, description: 是否可用于 Retrieve MetadataFilter }
        description: { type: string }

    MetadataSchema:
      type: object
      properties:
        entries:
          type: array
          items: { $ref: '#/components/schemas/MetadataSchemaEntry' }

    KBConfig:
      type: object
      properties:
        chunking: { $ref: '#/components/schemas/ChunkingPolicy' }
        metadata_schema: { $ref: '#/components/schemas/MetadataSchema' }
        default_top_k: { type: integer, minimum: 0, default: 0, description: "0 = 走 Adapter 默认" }
        vendor_extras: { type: object, additionalProperties: true }

    CreateKBRequest:
      type: object
      required: [name, provider_id, channel_id, model_version_id]
      properties:
        name: { type: string, maxLength: 120 }
        description: { type: string }
        icon: { type: string, format: uri }
        visibility: { type: string, enum: [private, tenant, public], default: private }
        provider_id: { type: integer, format: int64 }
        channel_id: { type: integer, format: int64 }
        model_version_id: { type: integer, format: int64 }
        config: { $ref: '#/components/schemas/KBConfig' }

    KnowledgeBaseDTO:
      type: object
      required: [bid, tenant_id, owner_account_id, name, state]
      properties:
        bid: { type: string, format: uuid }
        tenant_id: { type: integer, format: int64 }
        owner_account_id: { type: integer, format: int64 }
        name: { type: string }
        description: { type: string }
        icon: { type: string }
        visibility: { type: string, enum: [private, tenant, public] }
        provider_code: { type: string, description: "从 provider_id 解析" }
        model_version_id: { type: integer, format: int64 }
        upstream_store_id: { type: string, description: 厂商侧存储 ID }
        state: { type: string, enum: [active, archived, deleting] }
        active_doc_count: { type: integer }
        pending_doc_count: { type: integer }
        failed_doc_count: { type: integer }
        total_size_bytes: { type: integer, format: int64 }
        created_at: { type: string, format: date-time }
        updated_at: { type: string, format: date-time }

    DocumentDTO:
      type: object
      required: [bid, kb_bid, display_name, state, source_type]
      properties:
        bid: { type: string, format: uuid }
        kb_bid: { type: string, format: uuid }
        display_name: { type: string }
        mime_type: { type: string }
        size_bytes: { type: integer, format: int64 }
        state:
          type: string
          enum: [queued, ingesting, active, failed, deleting]
        error_code: { type: string }
        error_message: { type: string }
        source_type:
          type: string
          enum: [inline_upload, asset_ref, url]
        custom_metadata:
          type: object
          additionalProperties: true
        upstream_doc_id: { type: string }
        submitted_at: { type: string, format: date-time, nullable: true }
        activated_at: { type: string, format: date-time, nullable: true }
        failed_at: { type: string, format: date-time, nullable: true }
        created_at: { type: string, format: date-time }

    RetrievedChunk:
      type: object
      properties:
        text: { type: string }
        score: { type: number, format: float }
        document_bid: { type: string, format: uuid }
        document_title: { type: string }
        uri: { type: string }
        first_page: { type: integer }
        last_page: { type: integer }
        metadata: { type: object, additionalProperties: true }

    Citation:
      type: object
      properties:
        segment_start: { type: integer }
        segment_end: { type: integer }
        segment_text: { type: string }
        chunk_indices:
          type: array
          items: { type: integer }
        confidence_scores:
          type: array
          items: { type: number, format: float }

    RetrieveRequest:
      type: object
      required: [question]
      properties:
        question: { type: string, description: 检索问题, 非空 }
        kb_bids:
          type: array
          items: { type: string, format: uuid }
          description: 空时默认用 path :bid
        top_k: { type: integer, format: int32, description: "0 = 用 Adapter / KB.config 默认" }
        metadata_filter:
          type: object
          additionalProperties: true
          description: AST JSON ({and/or, field/op/value})
        rerank_options: { type: object, additionalProperties: true }
        vendor_extras: { type: object, additionalProperties: true }
        model_code: { type: string, description: "Retrieve 忽略, 仅 GroundedGenerate 用" }

    RetrieveResponse:
      type: object
      properties:
        chunks:
          type: array
          items: { $ref: '#/components/schemas/RetrievedChunk' }
        citations:
          type: array
          items: { $ref: '#/components/schemas/Citation' }
        usage_tokens: { type: integer }
        latency_ms: { type: integer }
        used_kb_bids:
          type: array
          items: { type: string, format: uuid }

    GroundedGenerateRequest:
      allOf:
        - $ref: '#/components/schemas/RetrieveRequest'
        - type: object
          properties:
            generation_extras:
              type: object
              additionalProperties: true
              description: temperature / max_tokens 等

    GroundedGenerateResponse:
      type: object
      properties:
        answer: { type: string, description: 基于检索结果生成的答案 }
        chunks:
          type: array
          items: { $ref: '#/components/schemas/RetrievedChunk' }
        citations:
          type: array
          items: { $ref: '#/components/schemas/Citation' }
        usage_tokens: { type: integer }
        latency_ms: { type: integer }

paths:
  /knowledge/bases:
    post:
      summary: 创建知识库
      operationId: createKB
      tags: [KB]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CreateKBRequest' }
      responses:
        '200':
          description: 创建成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/KnowledgeBaseDTO' }
        '400':
          description: 配置无效 (40030 / 40034 / 40031)
        '409':
          description: 同名 KB 已存在 (40930)
        '429':
          description: 配额耗尽 (42930)

    get:
      summary: 列知识库
      operationId: listKBs
      tags: [KB]
      parameters:
        - { name: state, in: query, schema: { type: string, enum: [active, archived, deleting] } }
        - { name: limit, in: query, schema: { type: integer, default: 20, maximum: 200 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
      responses:
        '200':
          description: KB 列表
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        properties:
                          items:
                            type: array
                            items: { $ref: '#/components/schemas/KnowledgeBaseDTO' }
                          total: { type: integer }

  /knowledge/bases/{bid}:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: 取知识库详情
      operationId: getKB
      tags: [KB]
      responses:
        '200':
          description: KB 详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/KnowledgeBaseDTO' }
        '404':
          description: KB 不存在 (40430)
        '403':
          description: 无权访问 (40330)
    delete:
      summary: 删除知识库 (软删 + 级联异步)
      operationId: deleteKB
      tags: [KB]
      description: |
        active → archived(可选) → deleting → 行消失.
        含活跃文档时拒删 (40934 ErrKBNotDeletable, 需先归档).
      responses:
        '200':
          description: "删除成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
        '404':
          description: KB 不存在 (40430)
        '409':
          description: KB 含活跃文档 (40934) / 已删除中 (40935)

  /knowledge/bases/{bid}/documents:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 上传文档 (multipart/form-data)
      operationId: uploadDocument
      tags: [Document]
      description: |
        三种来源:
          - inline_upload: 必填 file (≤100 MB)
          - asset_ref:     必填 source_ref (Creation BC asset BID)
          - url:           必填 source_ref (外部 URL)
        custom_metadata 须符合 KB.config.metadata_schema 校验.
      requestBody:
        required: true
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                display_name: { type: string }
                mime_type: { type: string }
                source_type:
                  type: string
                  enum: [inline_upload, asset_ref, url]
                  default: inline_upload
                source_ref: { type: string, description: "asset_ref 时是 Asset BID, url 时是 URL" }
                file: { type: string, format: binary, description: "仅 inline_upload 时填" }
                custom_metadata: { type: string, description: "JSON 字符串, 解析后按 metadata_schema 校验" }
      responses:
        '200':
          description: 已入队 (state=queued)
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/DocumentDTO' }
        '400':
          description: 来源/元数据校验失败 (40032 / 40035)
        '429':
          description: 单文件超限 (42931) / 元数据字段超限 (42932)

    get:
      summary: 列文档
      operationId: listDocuments
      tags: [Document]
      parameters:
        - { name: state, in: query, schema: { type: string, enum: [queued, ingesting, active, failed, deleting] } }
        - { name: limit, in: query, schema: { type: integer, default: 20, maximum: 200 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
      responses:
        '200':
          description: 文档列表
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        properties:
                          items:
                            type: array
                            items: { $ref: '#/components/schemas/DocumentDTO' }
                          total: { type: integer }

  /knowledge/bases/{bid}/documents/{doc_bid}:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      - { name: doc_bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: 取文档详情
      operationId: getDocument
      tags: [Document]
      responses:
        '200':
          description: 文档详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/DocumentDTO' }
        '404':
          description: KB / 文档不存在 (40430 / 40431)
    delete:
      summary: 删除文档 (软删 + 厂商侧异步)
      operationId: deleteDocument
      tags: [Document]
      responses:
        '200':
          description: "删除成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }

  /knowledge/bases/{bid}/retrieve:
    post:
      summary: 检索 (返 chunks + citations, 不生成答案)
      operationId: retrieveKB
      tags: [Query]
      parameters:
        - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/RetrieveRequest' }
      responses:
        '200':
          description: 检索结果
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/RetrieveResponse' }
        '400':
          description: question 空 / metadata_filter 无效 (40036 / 40033)

  /knowledge/bases/{bid}/generate:
    post:
      summary: 检索 + 生成 (Grounded Generation)
      operationId: groundedGenerateKB
      tags: [Query]
      description: |
        Adapter 不支持时返 50032 ErrCapabilityUnsupported (bailian / doubao 占位).
      parameters:
        - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/GroundedGenerateRequest' }
      responses:
        '200':
          description: 答案 + 引用
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/GroundedGenerateResponse' }
        '500':
          description: 厂商不支持 (50032) / 上游错误 (50230 / 50231 / 50410)

# 错误码段 (来源 internal/knowledge/domain/errors.go::GetErrorCode)
#
# 40030 ErrInvalidKnowledgeBaseConfig    KB 配置无效
# 40031 ErrInvalidMetadataSchema         元数据 schema 无效
# 40032 ErrMetadataValidationFailed      文档元数据不符合 schema
# 40033 ErrInvalidMetadataFilter         元数据过滤表达式无效
# 40034 ErrInvalidChunkingPolicy         切分策略无效
# 40035 ErrInvalidDocumentSource         文档来源无效
# 40036 ErrEmptyRetrieveQuestion         检索问题不能为空
# 40330 ErrKnowledgeBaseAccessDenied     无权访问该 KB
# 40430 ErrKnowledgeBaseNotFound         KB 不存在
# 40431 ErrDocumentNotFound              文档不存在
# 40432 ErrDocumentOperationNotFound     操作记录不存在
# 40433 ErrQuotaConfigNotFound           配额配置缺失
# 40930 ErrKBNameDuplicate               同名 KB 已存在
# 40931 ErrKBStateTransition             KB 状态转换非法
# 40932 ErrDocStateTransition            文档状态转换非法
# 40933 ErrOpStateTransition             操作状态转换非法
# 40934 ErrKBNotDeletable                KB 含活跃文档, 请先归档
# 40935 ErrKBAlreadyDeleting             KB 删除中
# 40936 ErrKBProviderImmutable           厂商绑定不可变更
# 42930 ErrQuotaExceeded                 配额耗尽
# 42931 ErrSingleFileTooLarge            单文件超限
# 42932 ErrMetadataEntriesExceeded       自定义元数据字段过多
# 50032 ErrCapabilityUnsupported         当前厂商不支持该能力
# 50230 ErrUpstreamTransient             上游暂时不可用
# 50231 ErrUpstreamPermanent             上游处理失败
# 50410 ErrUpstreamTimeout               上游超时
```
