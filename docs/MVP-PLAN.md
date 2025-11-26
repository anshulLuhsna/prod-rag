# MVP Plan: Banking & Finance Sector (5 Companies)

## MVP Scope

**Target Companies:**
1. **HDFCBANK.NS** - HDFC Bank Ltd (Private Bank, #3 by market cap)
2. **ICICIBANK.NS** - ICICI Bank Ltd (Private Bank, #5 by market cap)
3. **SBIN.NS** - State Bank of India (Public Bank, #9 by market cap)
4. **BAJFINANCE.NS** - Bajaj Finance Ltd (NBFC, #13 by market cap)
5. **KOTAKBANK.NS** - Kotak Mahindra Bank Ltd (Private Bank, #10 by market cap)

**Why These 5?**
- Represent different banking models (private, public, NBFC)
- High market cap = more data available
- Diverse enough to test comparative queries
- Cover ~40% of banking sector market cap

---

## MVP Data Requirements

### Documents to Ingest

| Document Type | Per Company | Total (5 companies) | Time Period |
|---------------|-------------|---------------------|-------------|
| Annual Reports | 3 | 15 documents | FY2022, FY2023, FY2024 |
| Quarterly Results | 8 | 40 documents | Q1-Q4 for FY2023 & FY2024 |
| **Total PDFs** | **11** | **55 documents** | ~2 years |
| News Articles | ~10/day | ~50/day | Last 30 days |
| Price Data | 500 days | 2,500 records | Last 2 years |
| Fundamentals | 8 quarters | 40 records | Last 2 years |

**Estimated Volume:**
- PDFs: ~55 documents × 50 pages avg = 2,750 pages
- Chunks: ~55 docs × 50 chunks/doc = ~2,750 chunks
- Vectors: ~2,750 chunks × 2 vectors (content + summary) = 5,500 vectors
- Storage: ~500 MB PDFs + ~2 GB vectors

---

## MVP Architecture (Simplified)

```
┌─────────────────────────────────────────────────────────────┐
│                    MVP STACK                                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Frontend: Next.js (Basic UI)                               │
│  Backend: FastAPI (Core endpoints only)                     │
│  Database: PostgreSQL (Local or Cloud SQL)                   │
│  Vector DB: Qdrant (Local or Cloud)                         │
│  Queue: Redis + Celery (Local)                              │
│  Storage: Local filesystem (or GCS bucket)                  │
│                                                              │
│  External APIs:                                              │
│  - Groq (LLM)                                                │
│  - OpenAI (Embeddings)                                       │
│  - LlamaParse (PDF parsing)                                  │
│  - yfinance (Market data)                                    │
│  - NSE API (Filings)                                         │
└─────────────────────────────────────────────────────────────┘
```

**Infrastructure Decision:**
- **Option A (Recommended for MVP):** Local development with Docker Compose
- **Option B:** Minimal GCP setup (Cloud SQL + Compute Engine)

---

## MVP Implementation Phases

### Phase 1: Foundation (Week 1)

#### Day 1-2: Project Setup
- [ ] Initialize backend (FastAPI)
- [ ] Initialize frontend (Next.js)
- [ ] Set up Docker Compose with:
  - PostgreSQL
  - Qdrant
  - Redis
- [ ] Configure environment variables
- [ ] Set up basic project structure

**Deliverable:** Services running locally, basic health checks

#### Day 3-4: Database Schema
- [ ] Create PostgreSQL tables (companies, documents, fundamentals, prices)
- [ ] Seed 5 companies data
- [ ] Create Qdrant collection
- [ ] Set up Alembic migrations

**Deliverable:** Database ready with 5 companies

#### Day 5: Basic API Endpoints
- [ ] `/health` - Health check
- [ ] `/api/companies` - List 5 companies
- [ ] `/api/companies/{symbol}` - Company details
- [ ] Basic authentication (JWT)

**Deliverable:** API serving company data

---

### Phase 2: Data Collection (Week 2)

#### Day 1-2: Document Collectors
- [ ] NSE API client for filings
- [ ] Company IR page scraper (5 companies)
- [ ] yfinance client for prices/fundamentals
- [ ] RSS news collector (banking/finance feeds)

**Files:**
```
backend/app/ingestion/collectors/
├── nse_collector.py
├── ir_page_scraper.py
├── yfinance_collector.py
└── news_collector.py
```

**Deliverable:** Can collect documents from all sources

#### Day 3: Manual Data Collection (One-time)
- [ ] Download 15 annual reports (3 years × 5 companies)
- [ ] Download 40 quarterly results (8 quarters × 5 companies)
- [ ] Store in `data/documents/` folder
- [ ] Verify all files downloaded

**Deliverable:** 55 PDF files ready for processing

#### Day 4-5: Document Parser
- [ ] LlamaParse integration
- [ ] Table extraction
- [ ] Section extraction
- [ ] Content hashing for deduplication

**Deliverable:** Can parse PDFs and extract structured content

---

### Phase 3: Ingestion Pipeline (Week 3)

#### Day 1-2: Chunking & Embedding
- [ ] Hierarchical chunking (512, 1024 tokens)
- [ ] Table-aware chunking
- [ ] OpenAI embedding pipeline
- [ ] Embedding cache (Redis)

**Deliverable:** Can chunk and embed documents

#### Day 3: Indexing
- [ ] Qdrant indexing with metadata
- [ ] Parent-child chunk relationships
- [ ] PostgreSQL metadata storage
- [ ] Batch processing for 55 documents

**Deliverable:** Documents indexed in Qdrant

#### Day 4-5: Celery Tasks
- [ ] `ingest_document` task
- [ ] `bootstrap_mvp` task (process all 55 docs)
- [ ] Progress tracking
- [ ] Error handling and retries

**Deliverable:** Automated ingestion pipeline

**Run Bootstrap:**
```bash
celery -A app.workers.celery_app call tasks.bootstrap_mvp
# Processes all 55 documents in parallel
```

---

### Phase 4: Retrieval System (Week 4)

#### Day 1-2: Basic Retrieval
- [ ] Qdrant vector search
- [ ] BM25 search (build index from chunks)
- [ ] Hybrid search (RRF fusion)
- [ ] Filter by company, period, doc_type

**Deliverable:** Can retrieve relevant documents

#### Day 3: Reranking
- [ ] CrossEncoder reranker
- [ ] Top-k filtering
- [ ] Parent chunk expansion

**Deliverable:** High-quality retrieval results

#### Day 4-5: Query Enhancement
- [ ] HyDE (optional, for complex queries)
- [ ] Query expansion
- [ ] Caching layer

**Deliverable:** Production-ready retrieval

---

### Phase 5: Agentic Workflow (Week 5)

#### Day 1-2: LangGraph Setup
- [ ] Define state schema
- [ ] Router node (classify queries)
- [ ] Retrieve node
- [ ] Grader node

**Deliverable:** Basic workflow nodes

#### Day 3: Generation
- [ ] Generate node (Groq llama-3.3-70b)
- [ ] Fact checker node
- [ ] Citation extraction

**Deliverable:** Can generate answers with citations

#### Day 4: Graph Construction
- [ ] Build StateGraph
- [ ] Add conditional edges
- [ ] Test end-to-end workflow

**Deliverable:** Complete agentic RAG workflow

#### Day 5: Testing & Refinement
- [ ] Test with 20+ sample queries
- [ ] Tune prompts
- [ ] Fix edge cases

**Deliverable:** Working RAG system

---

### Phase 6: API & Frontend (Week 6)

#### Day 1-2: API Endpoints
- [ ] `POST /api/query` - Submit query
- [ ] `GET /api/query/{id}` - Get result
- [ ] `POST /api/query/stream` - Streaming (SSE)
- [ ] `GET /api/companies/{symbol}/documents`
- [ ] `GET /api/companies/{symbol}/fundamentals`

**Deliverable:** Complete API

#### Day 3-5: Frontend
- [ ] Query page (Q&A interface)
- [ ] Company list page
- [ ] Company detail page
- [ ] Streaming response display
- [ ] Citation cards

**Deliverable:** Working UI

---

### Phase 7: Testing & Launch (Week 7)

#### Day 1-2: Integration Testing
- [ ] End-to-end query tests
- [ ] Test all 5 companies
- [ ] Test comparative queries
- [ ] Performance testing

**Deliverable:** System tested and validated

#### Day 3-4: Evaluation
- [ ] Create 30 golden QA pairs (6 per company)
- [ ] Run RAGAS evaluation
- [ ] Measure:
  - Retrieval recall (target: >85%)
  - Faithfulness (target: >90%)
  - Answer relevancy (target: >85%)

**Deliverable:** Evaluation report

#### Day 5: Documentation & Demo
- [ ] API documentation
- [ ] User guide
- [ ] Demo video
- [ ] Deployment guide

**Deliverable:** MVP ready for demo

---

## MVP Success Criteria

### Functional Requirements
- [x] Can answer questions about any of the 5 companies
- [x] Can compare companies (e.g., "Compare HDFC and ICICI ROE")
- [x] Provides accurate citations
- [x] Handles queries about financial metrics, trends, performance
- [x] Streaming responses work in UI

### Performance Requirements
- [x] Query latency <15s (p95) - relaxed for MVP
- [x] Retrieval recall >85% on golden set
- [x] Faithfulness >90%
- [x] System handles 10 concurrent users

### Data Requirements
- [x] 15 annual reports ingested
- [x] 40 quarterly results ingested
- [x] 2 years of price data
- [x] Current fundamentals
- [x] Last 30 days of news

---

## MVP Testing Queries

### Factual Queries
1. "What was HDFC Bank's revenue in FY2024?"
2. "What is ICICI Bank's current P/E ratio?"
3. "How much did SBI's net profit increase in Q2FY24?"
4. "What is Bajaj Finance's debt-to-equity ratio?"
5. "What was Kotak Bank's ROE in FY2023?"

### Comparative Queries
6. "Compare HDFC Bank and ICICI Bank's net interest margins"
7. "Which bank has higher ROE: HDFC or Kotak?"
8. "Compare the asset quality (NPA ratios) of all 5 banks"
9. "Which company has the highest market cap among these 5?"
10. "Compare loan growth rates across all 5 companies"

### Analytical Queries
11. "Why did HDFC Bank's stock price drop in Q3?"
12. "What were the key growth drivers for Bajaj Finance in FY2024?"
13. "What risks did SBI mention in their annual report?"
14. "What is the outlook for ICICI Bank's retail lending?"
15. "How has Kotak Bank's digital banking adoption changed?"

### Trend Queries
16. "Show me HDFC Bank's revenue trend over the last 2 years"
17. "How has ICICI Bank's NPA ratio changed?"
18. "What is the dividend yield trend for these 5 companies?"

---

## MVP Deployment Options

### Option 1: Local Development (Recommended)
```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:15
    ports: ["5432:5432"]
  
  qdrant:
    image: qdrant/qdrant
    ports: ["6333:6333"]
  
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
  
  backend:
    build: ./backend
    ports: ["8000:8000"]
  
  frontend:
    build: ./frontend
    ports: ["3000:3000"]
```

**Pros:** Fast setup, no cloud costs, easy debugging  
**Cons:** Not production-ready, manual deployment

### Option 2: Minimal GCP
- Cloud SQL (PostgreSQL) - db-f1-micro (~$7/month)
- Compute Engine (e2-small) - ~$15/month
- Cloud Storage bucket - ~$1/month
- **Total: ~$23/month**

**Pros:** Production-like, scalable  
**Cons:** Higher cost, more setup

---

## MVP Timeline Summary

| Week | Phase | Key Deliverables |
|------|-------|------------------|
| 1 | Foundation | Services running, DB schema, basic API |
| 2 | Data Collection | Collectors built, 55 PDFs downloaded |
| 3 | Ingestion | All documents parsed, chunked, indexed |
| 4 | Retrieval | Hybrid search working, reranking |
| 5 | Agentic Workflow | LangGraph workflow complete |
| 6 | API & Frontend | Full-stack application |
| 7 | Testing & Launch | Evaluated, documented, demo-ready |

**Total: 7 weeks to MVP**

---

## MVP Cost Estimate

### Development Costs
- **LlamaParse:** 55 docs × ~$0.003/page = ~$8 (one-time)
- **OpenAI Embeddings:** 2,750 chunks × $0.00013/1K tokens = ~$5 (one-time)
- **Groq API:** Free tier sufficient for testing
- **Infrastructure:** $0 (local) or $23/month (GCP)

### Ongoing Costs (Post-MVP)
- **News collection:** ~$2/month (RSS free)
- **Price updates:** Free (yfinance)
- **API calls:** ~$10-20/month (Groq + OpenAI)

**Total MVP Cost: ~$13-43 (one-time + first month)**

---

## MVP Next Steps (Post-Launch)

### Phase 2 Enhancements
1. Add remaining 45 NIFTY companies
2. Add Knowledge Graph (Neo4j)
3. Multi-turn conversation
4. Advanced analytics (charts, trends)
5. User authentication & personalization

### Phase 3 Features
1. Portfolio analysis
2. Earnings call transcripts
3. Sentiment analysis
4. Export to PDF/Excel
5. Mobile app

---

## MVP Risk Mitigation

| Risk | Mitigation |
|------|------------|
| LlamaParse rate limits | Process in batches, add delays |
| Missing documents | Manual download fallback |
| Low retrieval quality | Start with simpler chunking, tune later |
| API costs | Use free tiers, cache aggressively |
| Timeline delays | Focus on core features first |

---

## MVP Team Requirements

**Minimum Team:**
- 1 Backend Developer (Python/FastAPI)
- 1 Frontend Developer (Next.js/React)
- 1 DevOps (Docker, deployment)

**Optional:**
- 1 Data Engineer (for ingestion pipeline)
- 1 QA Engineer (for testing)

**Estimated Effort:** 7 weeks × 2-3 developers = 14-21 person-weeks

---

## MVP Success Metrics

### Technical Metrics
- ✅ 55 documents ingested successfully
- ✅ >85% retrieval recall
- ✅ >90% faithfulness
- ✅ <15s query latency
- ✅ Zero critical bugs

### Business Metrics
- ✅ Can answer 90%+ of test queries
- ✅ Citations are accurate and verifiable
- ✅ UI is intuitive and responsive
- ✅ System is stable (no crashes)

---

*This MVP plan focuses on proving the core RAG concept with a manageable dataset before scaling to all 50 companies.*

