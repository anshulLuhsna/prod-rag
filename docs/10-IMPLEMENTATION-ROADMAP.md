# 10 - Implementation Roadmap

## Overview

This document provides a detailed week-by-week implementation plan for the NIFTY 50 Agentic RAG System. Total estimated duration: **8 weeks**.

---

## Timeline Overview

```
Week 1-2: Foundation & Infrastructure
Week 3:   Ingestion Pipeline
Week 4:   Retrieval System
Week 5:   Agentic Workflow
Week 6:   API & Frontend
Week 7:   Safety & Quality
Week 8:   Production & Launch
```

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        8-WEEK IMPLEMENTATION TIMELINE                         │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  Week 1  │ Week 2  │ Week 3  │ Week 4  │ Week 5  │ Week 6  │ Week 7  │ Week 8│
│          │         │         │         │         │         │         │       │
│ ████████████████   │         │         │         │         │         │       │
│ Infrastructure     │         │         │         │         │         │       │
│                    │         │         │         │         │         │       │
│          │ ████████████████  │         │         │         │         │       │
│          │ Data Model        │         │         │         │         │       │
│                    │         │         │         │         │         │       │
│                    │ ████████████████  │         │         │         │       │
│                    │ Ingestion         │         │         │         │       │
│                              │         │         │         │         │       │
│                              │ ████████████████  │         │         │       │
│                              │ Retrieval         │         │         │       │
│                                        │         │         │         │       │
│                                        │ ████████████████  │         │       │
│                                        │ Agentic Workflow  │         │       │
│                                                  │         │         │       │
│                                                  │ ████████████████  │       │
│                                                  │ API & Frontend    │       │
│                                                            │         │       │
│                                                            │ ████████████████│
│                                                            │ Safety & Launch │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Foundation & Infrastructure (Week 1-2)

### Week 1: Project Setup & GCP Infrastructure

#### Day 1-2: Project Initialization

**Tasks:**
- [ ] Create GitHub repository with branch protection
- [ ] Set up monorepo structure
- [ ] Initialize Python backend (FastAPI)
- [ ] Initialize Next.js frontend
- [ ] Configure pre-commit hooks (black, isort, eslint)
- [ ] Set up GitHub Actions for CI

**Deliverables:**
```
nifty50-rag/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   └── core/
│   │       ├── config.py
│   │       └── dependencies.py
│   ├── requirements.txt
│   └── pyproject.toml
├── frontend/
│   ├── app/
│   ├── package.json
│   └── tsconfig.json
├── infra/
│   └── terraform/
├── docs/
├── .github/
│   └── workflows/
├── docker-compose.yml
└── README.md
```

#### Day 3-4: GCP Infrastructure (Terraform)

**Tasks:**
- [ ] Create GCP project and enable APIs
- [ ] Set up Terraform state backend (GCS)
- [ ] Create VPC network and firewall rules
- [ ] Provision Compute Engine VM
- [ ] Set up Cloud SQL (PostgreSQL)
- [ ] Create Cloud Storage buckets
- [ ] Configure Secret Manager

**Commands:**
```bash
cd infra/terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

#### Day 5: Docker & Local Development

**Tasks:**
- [ ] Write Dockerfiles for backend/frontend
- [ ] Configure docker-compose.yml
- [ ] Set up local Qdrant container
- [ ] Set up local Redis container
- [ ] Create .env.example and document environment variables
- [ ] Test local development environment

**Verification:**
```bash
docker-compose up -d
curl http://localhost:8000/health  # Backend
curl http://localhost:3000         # Frontend
curl http://localhost:6333/collections  # Qdrant
```

---

### Week 2: Database & Core Services

#### Day 1-2: PostgreSQL Schema

**Tasks:**
- [ ] Install TimescaleDB extension
- [ ] Create all database tables (see 02-DATA-MODEL.md)
- [ ] Set up Alembic for migrations
- [ ] Create initial migration
- [ ] Seed NIFTY 50 companies data
- [ ] Test database connections

**Files to Create:**
```
backend/
├── alembic/
│   ├── versions/
│   │   ├── 001_create_companies.py
│   │   ├── 002_create_fundamentals.py
│   │   ├── 003_create_prices.py
│   │   ├── 004_create_documents.py
│   │   └── ...
│   └── env.py
└── app/
    └── models/
        ├── company.py
        ├── fundamental.py
        ├── price.py
        └── document.py
```

#### Day 3-4: Qdrant Setup

**Tasks:**
- [ ] Create Qdrant collection with schema
- [ ] Configure multi-vector setup (content + summary)
- [ ] Set up payload indexes
- [ ] Write Qdrant client wrapper
- [ ] Test vector operations (insert, search, delete)

**Code:**
```python
# backend/app/services/qdrant_service.py
class QdrantService:
    def create_collection(self): ...
    def upsert_points(self, points: List[PointStruct]): ...
    def search(self, query_vector, filters, top_k): ...
    def delete_by_document_id(self, document_id): ...
```

#### Day 5: Redis & Celery Setup

**Tasks:**
- [ ] Configure Redis connection
- [ ] Set up Celery app with Redis broker
- [ ] Create Celery configuration
- [ ] Implement basic task (health check)
- [ ] Set up Celery Beat for scheduled tasks
- [ ] Test task execution

**Files:**
```
backend/
├── app/
│   └── workers/
│       ├── __init__.py
│       ├── celery_app.py
│       └── tasks/
│           ├── __init__.py
│           └── health.py
└── celeryconfig.py
```

---

## Phase 2: Ingestion Pipeline (Week 3)

### Day 1-2: Document Collectors

**Tasks:**
- [ ] Implement NSE/BSE filing collector
- [ ] Implement company IR page scraper
- [ ] Implement RSS news collector
- [ ] Implement yfinance price collector
- [ ] Implement yfinance fundamentals collector
- [ ] Add rate limiting and retry logic

**Files:**
```
backend/app/ingestion/collectors/
├── __init__.py
├── base.py
├── annual_reports.py
├── quarterly_results.py
├── news.py
├── prices.py
└── fundamentals.py
```

### Day 3: Document Parser (LlamaParse)

**Tasks:**
- [ ] Set up LlamaParse client
- [ ] Implement PDF parsing with table extraction
- [ ] Implement section extraction
- [ ] Implement metadata extraction
- [ ] Add content hashing for deduplication
- [ ] Test with sample annual reports

**Code:**
```python
# backend/app/ingestion/parser.py
class DocumentParser:
    async def parse(self, file_path: str, doc_type: str) -> ParsedDocument: ...
    def _extract_tables(self, content: str) -> List[dict]: ...
    def _extract_sections(self, content: str) -> List[dict]: ...
```

### Day 4: Chunking & Embedding

**Tasks:**
- [ ] Implement hierarchical chunking
- [ ] Implement semantic chunking
- [ ] Implement table-aware chunking
- [ ] Set up OpenAI embeddings client
- [ ] Implement batch embedding
- [ ] Implement embedding cache

**Files:**
```
backend/app/ingestion/
├── chunker.py
├── embedder.py
└── indexer.py
```

### Day 5: Celery Tasks & Bootstrap

**Tasks:**
- [ ] Implement `ingest_document` task
- [ ] Implement `collect_news` scheduled task
- [ ] Implement `collect_prices` scheduled task
- [ ] Implement `bootstrap_all` task
- [ ] Add comprehensive logging
- [ ] Test full ingestion pipeline

**Verification:**
```bash
# Trigger bootstrap
celery -A app.workers.celery_app call tasks.bootstrap_all

# Check Qdrant
curl http://localhost:6333/collections/nifty_50_financial_kb
```

---

## Phase 3: Retrieval System (Week 4)

### Day 1-2: Vector & BM25 Search

**Tasks:**
- [ ] Implement Qdrant vector search
- [ ] Implement BM25 search with rank_bm25
- [ ] Build BM25 index from existing documents
- [ ] Add filter support (company, period, doc_type)
- [ ] Test individual retrievers

**Files:**
```
backend/app/retrieval/
├── __init__.py
├── vector_search.py
├── bm25_search.py
├── types.py
└── filters.py
```

### Day 3: Hybrid Search & Reranking

**Tasks:**
- [ ] Implement RRF fusion
- [ ] Implement hybrid searcher
- [ ] Set up CrossEncoder reranker
- [ ] Implement reranking pipeline
- [ ] Tune weights and thresholds

**Code:**
```python
# backend/app/retrieval/hybrid.py
class HybridSearcher:
    async def search(self, query, top_k, filters) -> List[SearchResult]: ...

# backend/app/retrieval/reranker.py
class Reranker:
    def rerank(self, query, results, top_k) -> List[SearchResult]: ...
```

### Day 4: Query Enhancement

**Tasks:**
- [ ] Implement HyDE query enhancement
- [ ] Implement query expansion
- [ ] Implement parent chunk expansion
- [ ] Add caching layer (Redis)
- [ ] Test with various query types

### Day 5: Retrieval Pipeline Integration

**Tasks:**
- [ ] Create unified RetrievalPipeline class
- [ ] Add metrics collection
- [ ] Write integration tests
- [ ] Benchmark retrieval performance
- [ ] Document retrieval API

**Verification:**
```python
# Test retrieval
pipeline = RetrievalPipeline(...)
results = await pipeline.retrieve(
    query="What was Reliance revenue in FY2024?",
    top_k=5,
    filters={"company_symbol": "RELIANCE.NS"}
)
assert len(results) >= 1
assert results[0].score > 0.7
```

---

## Phase 4: Agentic Workflow (Week 5)

### Day 1-2: LangGraph State & Nodes

**Tasks:**
- [ ] Define AgenticRAGState TypedDict
- [ ] Implement router node
- [ ] Implement retrieve node
- [ ] Implement grader node
- [ ] Implement rewrite node
- [ ] Set up Groq LLM client

**Files:**
```
backend/app/agents/
├── __init__.py
├── state.py
├── nodes/
│   ├── __init__.py
│   ├── router.py
│   ├── retrieve.py
│   ├── grader.py
│   └── rewrite.py
└── prompts/
    ├── router.py
    ├── grader.py
    └── rewrite.py
```

### Day 3: Generation & Fact Checking

**Tasks:**
- [ ] Implement generate node
- [ ] Implement fact_check node
- [ ] Implement citation node
- [ ] Implement direct_answer node
- [ ] Implement web_search node (fallback)
- [ ] Test individual nodes

### Day 4: Graph Construction

**Tasks:**
- [ ] Build StateGraph
- [ ] Add all nodes
- [ ] Add conditional edges
- [ ] Implement routing logic
- [ ] Add MemorySaver checkpointer
- [ ] Compile graph

**Code:**
```python
# backend/app/agents/graph.py
def create_rag_graph() -> StateGraph:
    workflow = StateGraph(AgenticRAGState)
    # Add nodes...
    # Add edges...
    return workflow

graph = create_rag_graph().compile(checkpointer=MemorySaver())
```

### Day 5: HITL & Integration

**Tasks:**
- [ ] Implement HITL check node
- [ ] Add interrupt_before for HITL
- [ ] Implement state persistence (PostgreSQL)
- [ ] Create workflow runner
- [ ] Write end-to-end tests
- [ ] Add LangSmith tracing

**Verification:**
```python
# Test full workflow
result = await run_query("What was TCS revenue in FY2024?")
assert result["generated_response"] is not None
assert len(result["citations"]) > 0
assert result["fact_check_result"].is_faithful
```

---

## Phase 5: API & Frontend (Week 6)

### Day 1-2: FastAPI Endpoints

**Tasks:**
- [ ] Implement auth endpoints (login, refresh, me)
- [ ] Implement query endpoints (POST, GET, stream)
- [ ] Implement company endpoints
- [ ] Implement document endpoints
- [ ] Implement HITL endpoints
- [ ] Add JWT authentication
- [ ] Add rate limiting

**Files:**
```
backend/app/api/
├── __init__.py
├── deps.py
├── auth.py
├── routes/
│   ├── query.py
│   ├── companies.py
│   ├── documents.py
│   └── hitl.py
└── schemas/
    ├── query.py
    ├── company.py
    └── document.py
```

### Day 3: SSE Streaming

**Tasks:**
- [ ] Implement SSE endpoint for streaming
- [ ] Stream node updates
- [ ] Stream token generation
- [ ] Stream citations
- [ ] Test with curl/Postman
- [ ] Document streaming protocol

### Day 4-5: Next.js Frontend

**Tasks:**
- [ ] Set up shadcn/ui components
- [ ] Implement dashboard page
- [ ] Implement query page with streaming
- [ ] Implement company list page
- [ ] Implement company detail page
- [ ] Implement HITL admin page
- [ ] Add React Query hooks
- [ ] Style with Tailwind

**Pages:**
```
frontend/app/
├── (auth)/
│   └── login/page.tsx
├── (dashboard)/
│   ├── page.tsx
│   ├── query/page.tsx
│   ├── companies/
│   │   ├── page.tsx
│   │   └── [symbol]/page.tsx
│   └── layout.tsx
└── admin/
    └── hitl/page.tsx
```

---

## Phase 6: Safety & Quality (Week 7)

### Day 1-2: Guardrails

**Tasks:**
- [ ] Implement input validation guardrails
- [ ] Implement PII detection
- [ ] Implement topic filtering
- [ ] Implement output guardrails
- [ ] Add financial disclaimer
- [ ] Test guardrail effectiveness

**Files:**
```
backend/app/guardrails/
├── __init__.py
├── input_filter.py
├── pii_detector.py
├── topic_filter.py
├── output_filter.py
└── compliance.py
```

### Day 3: Evaluation Setup

**Tasks:**
- [ ] Create golden QA dataset (50+ pairs)
- [ ] Implement RAGAS evaluation
- [ ] Implement trajectory evaluation
- [ ] Set up LangSmith evaluation
- [ ] Create evaluation scripts
- [ ] Run baseline evaluation

### Day 4-5: Monitoring & Alerting

**Tasks:**
- [ ] Add Prometheus metrics
- [ ] Create Grafana dashboards
- [ ] Set up alerting rules
- [ ] Implement health checks
- [ ] Add structured logging
- [ ] Test monitoring stack

---

## Phase 7: Production & Launch (Week 8)

### Day 1-2: Production Deployment

**Tasks:**
- [ ] Deploy to GCP via Terraform
- [ ] Configure SSL certificates
- [ ] Set up Nginx reverse proxy
- [ ] Configure Cloud SQL connection
- [ ] Deploy Docker containers
- [ ] Verify all services running

**Commands:**
```bash
# Deploy infrastructure
cd infra/terraform
terraform apply

# Deploy application
ssh nifty50-rag-server
cd /opt/nifty50-rag
docker-compose -f docker-compose.prod.yml up -d
```

### Day 3: Data Bootstrap

**Tasks:**
- [ ] Run full bootstrap (all companies, 3 years)
- [ ] Verify document ingestion
- [ ] Verify vector index
- [ ] Verify price data
- [ ] Verify fundamentals data
- [ ] Run evaluation on production

### Day 4: Load Testing & Optimization

**Tasks:**
- [ ] Run load tests (locust)
- [ ] Identify bottlenecks
- [ ] Optimize slow queries
- [ ] Tune caching
- [ ] Verify rate limiting
- [ ] Document performance baseline

### Day 5: Documentation & Handoff

**Tasks:**
- [ ] Write API documentation
- [ ] Write runbooks
- [ ] Create architecture diagrams
- [ ] Document deployment process
- [ ] Create troubleshooting guide
- [ ] Final review and launch

---

## Success Criteria Checklist

### Functional Requirements

- [ ] Can answer factual questions about any NIFTY 50 company
- [ ] Can compare multiple companies
- [ ] Can analyze trends and provide insights
- [ ] Citations are accurate and verifiable
- [ ] HITL workflow functions correctly
- [ ] Streaming responses work in UI

### Performance Requirements

- [ ] Query latency <10s (p95)
- [ ] Retrieval recall >90% on golden set
- [ ] Faithfulness score >95%
- [ ] Hallucination rate <2%
- [ ] System handles 100 concurrent users

### Data Requirements

- [ ] 150 annual reports ingested (3 years × 50 companies)
- [ ] 400 quarterly results ingested
- [ ] 3 years of price data
- [ ] Current fundamentals for all companies
- [ ] News collection running (<5 min latency)

### Operational Requirements

- [ ] Full observability via LangSmith
- [ ] Prometheus metrics exposed
- [ ] Grafana dashboards configured
- [ ] Alerting rules active
- [ ] Backup and recovery tested

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| LlamaParse API limits | Implement rate limiting, batch processing |
| Groq API downtime | Add OpenAI fallback |
| Large PDF parsing failures | Implement chunked parsing, retry logic |
| Low retrieval quality | Tune hybrid weights, add more chunking strategies |
| High hallucination rate | Strengthen fact-checking, lower confidence thresholds |
| GCP cost overruns | Set budget alerts, use preemptible VMs for workers |

---

## Post-Launch Roadmap

### Phase 2 Features (Month 2-3)

- [ ] Knowledge Graph with Neo4j
- [ ] Multi-turn conversation memory
- [ ] Custom company watchlists
- [ ] Email alerts for news
- [ ] Mobile-responsive UI
- [ ] User feedback loop

### Phase 3 Features (Month 4-6)

- [ ] Portfolio analysis
- [ ] Earnings call transcripts
- [ ] Sentiment analysis dashboard
- [ ] Comparison with sector peers
- [ ] Export to PDF/Excel
- [ ] API for third-party integration

---

## Contact & Support

For questions during implementation:
- Technical issues: Create GitHub issue
- Architecture decisions: Refer to docs/01-ARCHITECTURE.md
- Data model questions: Refer to docs/02-DATA-MODEL.md

---

*Document generated for NIFTY 50 Agentic RAG System*
*Last updated: November 2024*

