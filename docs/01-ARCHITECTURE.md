# 01 - Architecture Overview

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   FRONTEND                                       │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                         Next.js Application                              │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │    │
│  │  │ Dashboard│ │  Query   │ │Companies │ │ Compare  │ │  Admin   │      │    │
│  │  │   Page   │ │   Page   │ │   Page   │ │   Page   │ │   HITL   │      │    │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘      │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        │ HTTPS / REST API
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   BACKEND                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                         FastAPI Application                              │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │    │
│  │  │  Query API   │ │ Company API  │ │ Ingest API   │ │   HITL API   │   │    │
│  │  └──────┬───────┘ └──────────────┘ └──────┬───────┘ └──────────────┘   │    │
│  │         │                                  │                            │    │
│  │         ▼                                  ▼                            │    │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │    │
│  │  │                    LangGraph Agentic Workflow                    │   │    │
│  │  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐        │   │    │
│  │  │  │ Router │→│Retrieve│→│ Grade  │→│Generate│→│  Cite  │        │   │    │
│  │  │  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘        │   │    │
│  │  │       ↑          │          │          │                        │   │    │
│  │  │       └──────────┴──Rewrite─┴──────────┘                        │   │    │
│  │  └─────────────────────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                         Celery Workers                                   │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │    │
│  │  │ News Collect │ │Price Collect │ │Doc Ingest    │ │ Bootstrap    │   │    │
│  │  │  (5 min)     │ │  (daily)     │ │  (on-demand) │ │  (one-time)  │   │    │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────────┘
                    │                    │                    │
                    ▼                    ▼                    ▼
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│       Qdrant         │  │     PostgreSQL       │  │        Redis         │
│   (Vector Store)     │  │   + TimescaleDB      │  │   (Cache + Queue)    │
│                      │  │                      │  │                      │
│ - Document embeddings│  │ - Companies          │  │ - Query cache        │
│ - Summary vectors    │  │ - Fundamentals       │  │ - Celery broker      │
│ - Parent-child links │  │ - Prices (timeseries)│  │ - Session store      │
│                      │  │ - Documents metadata │  │                      │
└──────────────────────┘  └──────────────────────┘  └──────────────────────┘
                    │                    │
                    ▼                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                            External Services                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │   Groq   │ │  OpenAI  │ │LlamaParse│ │ LangSmith│ │   GCP    │           │
│  │  (LLM)   │ │(Embeddings)│ │(Parsing) │ │(Tracing) │ │(Storage) │           │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘           │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Component Breakdown

### 1. Frontend Layer (Next.js)

**Purpose**: User interface for querying, browsing companies, and admin functions.

| Component | Responsibility |
|-----------|---------------|
| Dashboard | Market overview, trending queries, recent news |
| Query Page | Natural language Q&A with streaming responses |
| Companies | Browse/search NIFTY 50, view details |
| Compare | Side-by-side company comparison |
| Admin HITL | Human review queue for flagged queries |

**Key Technologies**:
- Next.js 14 with App Router
- Server Components for data fetching
- Streaming responses via Server-Sent Events
- shadcn/ui component library

---

### 2. API Layer (FastAPI)

**Purpose**: REST API serving frontend and exposing system capabilities.

```
/api/v1/
├── query/
│   ├── POST /              # Submit new query
│   ├── GET /{id}           # Get query result
│   └── GET /{id}/stream    # Stream response (SSE)
├── companies/
│   ├── GET /               # List all companies
│   ├── GET /{symbol}       # Company details
│   ├── GET /{symbol}/fundamentals
│   ├── GET /{symbol}/prices
│   └── GET /{symbol}/documents
├── ingest/
│   ├── POST /document      # Ingest single document
│   ├── POST /bootstrap     # Trigger full bootstrap
│   └── GET /status         # Ingestion status
├── hitl/
│   ├── GET /pending        # List pending reviews
│   ├── POST /{id}/approve  # Approve action
│   └── POST /{id}/reject   # Reject action
└── health/
    └── GET /               # Health check
```

**Key Features**:
- JWT authentication
- Rate limiting
- Request validation (Pydantic)
- OpenAPI documentation
- CORS for frontend

---

### 3. Agentic Workflow Layer (LangGraph)

**Purpose**: Orchestrate the RAG pipeline with self-correction and quality checks.

```
                                    ┌─────────────┐
                                    │   START     │
                                    └──────┬──────┘
                                           │
                                           ▼
                                    ┌─────────────┐
                              ┌─────│   Router    │─────┐
                              │     └─────────────┘     │
                              │            │            │
                              ▼            ▼            ▼
                       ┌──────────┐ ┌──────────┐ ┌──────────┐
                       │  Direct  │ │ Retrieve │ │Web Search│
                       │  Answer  │ │          │ │(fallback)│
                       └────┬─────┘ └────┬─────┘ └────┬─────┘
                            │            │            │
                            │            ▼            │
                            │     ┌─────────────┐     │
                            │     │   Grader    │     │
                            │     └──────┬──────┘     │
                            │            │            │
                            │      ┌─────┴─────┐      │
                            │      │           │      │
                            │      ▼           ▼      │
                            │ ┌────────┐  ┌────────┐  │
                            │ │Relevant│  │Rewrite │──┘
                            │ └───┬────┘  └────────┘
                            │     │
                            ▼     ▼
                       ┌─────────────────┐
                       │    Generator    │
                       └────────┬────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  Fact Checker   │
                       └────────┬────────┘
                                │
                          ┌─────┴─────┐
                          │           │
                          ▼           ▼
                    ┌──────────┐ ┌──────────┐
                    │  Passed  │ │Regenerate│
                    └────┬─────┘ └────┬─────┘
                         │            │
                         │            └────────┐
                         ▼                     │
                  ┌─────────────┐              │
                  │  Citation   │◄─────────────┘
                  └──────┬──────┘
                         │
                         ▼
                  ┌─────────────┐
                  │    HITL?    │───► Human Review
                  └──────┬──────┘
                         │
                         ▼
                  ┌─────────────┐
                  │     END     │
                  └─────────────┘
```

**Nodes**:

| Node | Purpose | LLM Used |
|------|---------|----------|
| Router | Classify query → route to appropriate path | Groq (fast) |
| Retrieve | Execute hybrid search (vector + BM25) | None |
| Grader | Binary relevance check per document | Groq (fast) |
| Rewrite | Reformulate query for better retrieval | Groq |
| Generator | Synthesize answer from context | Groq (70B) |
| Fact Checker | Verify claims against sources | Groq |
| Citation | Extract and format source references | None (rule-based) |
| HITL | Pause for human review if flagged | None |

---

### 4. Ingestion Layer (Celery Workers)

**Purpose**: Collect, parse, and index documents asynchronously.

```
┌─────────────────────────────────────────────────────────────────┐
│                     Ingestion Pipeline                          │
│                                                                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │ Collect  │───►│  Parse   │───►│  Chunk   │───►│  Embed   │  │
│  │          │    │(LlamaParse)   │          │    │          │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│       │                                               │         │
│       │                                               ▼         │
│       │                                        ┌──────────┐     │
│       │                                        │  Index   │     │
│       │                                        │ (Qdrant) │     │
│       │                                        └──────────┘     │
│       │                                               │         │
│       ▼                                               ▼         │
│  ┌──────────┐                                  ┌──────────┐     │
│  │ Metadata │─────────────────────────────────►│PostgreSQL│     │
│  │  Store   │                                  │          │     │
│  └──────────┘                                  └──────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

**Scheduled Tasks**:

| Task | Schedule | Data Source |
|------|----------|-------------|
| `collect_news` | Every 5 minutes | RSS feeds (ET, Moneycontrol) |
| `collect_prices` | Daily 6 PM IST | yfinance |
| `collect_fundamentals` | Weekly | yfinance, Screener.in |
| `check_new_filings` | Every 30 minutes | NSE/BSE announcements |

---

### 5. Data Layer

#### Qdrant (Vector Database)

**Collection**: `nifty_50_financial_kb`

```python
{
    "vectors": {
        "content": {
            "size": 3072,  # text-embedding-3-large
            "distance": "Cosine"
        },
        "summary": {
            "size": 3072,
            "distance": "Cosine"
        }
    },
    "payload_schema": {
        "company_symbol": "keyword",
        "document_type": "keyword",
        "fiscal_period": "keyword",
        "section": "keyword",
        "parent_id": "keyword",
        "content_hash": "keyword",
        "ingestion_timestamp": "datetime"
    }
}
```

#### PostgreSQL (Relational Database)

**Key Tables**:
- `companies` - NIFTY 50 master data
- `fundamentals` - Financial metrics (quarterly/annual)
- `prices` - OHLCV timeseries (TimescaleDB hypertable)
- `documents` - Document metadata and ingestion tracking
- `queries` - Query history and responses
- `hitl_reviews` - Human review queue

#### Redis (Cache + Queue)

**Usage**:
- Query result caching (TTL: 1 hour)
- Embedding cache (TTL: 24 hours)
- Celery task broker
- Rate limiting counters

---

### 6. External Services

| Service | Purpose | API |
|---------|---------|-----|
| **Groq** | LLM inference (llama-3.3-70b) | REST API |
| **OpenAI** | Embeddings (text-embedding-3-large) | REST API |
| **LlamaParse** | PDF parsing with table extraction | REST API |
| **LangSmith** | Tracing and observability | REST API |
| **GCP Cloud Storage** | PDF storage and backups | GCS SDK |

---

## Data Flow Diagrams

### Query Flow

```
User Query
    │
    ▼
┌─────────────────┐
│  FastAPI        │
│  /api/v1/query  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  LangGraph      │────►│  Redis Cache    │
│  Workflow       │     │  (check cache)  │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Router Node    │────►│  Groq LLM       │
│  (classify)     │     │  (classify)     │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Retrieve Node  │────►│  Qdrant         │────►│  PostgreSQL     │
│                 │     │  (vector search)│     │  (metadata)     │
└────────┬────────┘     └─────────────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Generate Node  │────►│  Groq LLM       │
│                 │     │  (70B model)    │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│  Response       │
│  (with citations)│
└─────────────────┘
```

### Ingestion Flow

```
Document Source (PDF/News/Filing)
    │
    ▼
┌─────────────────┐
│  Celery Task    │
│  (async)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Download/Fetch │────►│  GCP Storage    │
│                 │     │  (store raw)    │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  LlamaParse     │────►│  LlamaParse API │
│  (extract)      │     │                 │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│  Chunker        │
│  (hierarchical) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Embedder       │────►│  OpenAI API     │
│                 │     │  (embeddings)   │
└────────┬────────┘     └─────────────────┘
         │
         ├────────────────────┐
         ▼                    ▼
┌─────────────────┐  ┌─────────────────┐
│  Qdrant         │  │  PostgreSQL     │
│  (index vectors)│  │  (store meta)   │
└─────────────────┘  └─────────────────┘
```

---

## Security Architecture

### Authentication Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Client  │────►│  FastAPI │────►│   JWT    │
│          │     │  /login  │     │  Verify  │
└──────────┘     └──────────┘     └──────────┘
                       │
                       ▼
                ┌──────────────┐
                │  PostgreSQL  │
                │  (users)     │
                └──────────────┘
```

### Security Layers

1. **Network**: GCP VPC with firewall rules
2. **Transport**: HTTPS/TLS for all traffic
3. **Authentication**: JWT tokens with refresh
4. **Authorization**: Role-based access (admin, user)
5. **Input Validation**: Pydantic schemas
6. **Rate Limiting**: Redis-based per-user limits
7. **Guardrails**: Input/output filtering

---

## Scalability Considerations

### Horizontal Scaling

| Component | Scaling Strategy |
|-----------|-----------------|
| FastAPI | Multiple instances behind load balancer |
| Celery Workers | Add workers for increased throughput |
| Qdrant | Cluster mode with sharding |
| PostgreSQL | Read replicas for queries |

### Performance Optimizations

1. **Caching**: Redis for query results, embeddings
2. **Connection Pooling**: SQLAlchemy, Qdrant client
3. **Async Operations**: FastAPI async endpoints
4. **Batch Processing**: Bulk embedding, bulk indexing
5. **Streaming**: SSE for long responses

---

## Failure Handling

### Retry Strategies

| Operation | Retries | Backoff |
|-----------|---------|---------|
| LLM API calls | 3 | Exponential |
| Embedding API | 3 | Exponential |
| Database writes | 2 | Linear |
| Document parsing | 2 | None |

### Circuit Breakers

- LLM API: Open after 5 consecutive failures
- External data sources: Open after 3 failures

### Graceful Degradation

1. If Groq fails → Return cached response or error
2. If Qdrant fails → Return error (no fallback)
3. If embedding fails → Queue for retry
4. If news collection fails → Log and continue

---

## Monitoring Points

| Component | Metrics |
|-----------|---------|
| FastAPI | Request latency, error rate, throughput |
| LangGraph | Node execution time, retry count, path distribution |
| Qdrant | Query latency, index size, memory usage |
| PostgreSQL | Query time, connection pool, disk usage |
| Celery | Task success rate, queue depth, worker utilization |
| LLM | Token usage, latency, error rate |

---

## Next Document

Continue to [02-DATA-MODEL.md](./02-DATA-MODEL.md) for detailed database schemas and data structures.

