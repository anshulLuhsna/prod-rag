# NIFTY 50 Agentic RAG System - Documentation Index

## Project Overview

An enterprise-grade, production-ready Agentic Retrieval-Augmented Generation (RAG) system for NIFTY 50 financial analysis. Built with LangGraph v1, FastAPI, Next.js, Qdrant, PostgreSQL, and deployed on GCP.

## Quick Reference

| Aspect | Choice |
|--------|--------|
| **LLM Provider** | Groq (llama-3.3-70b-versatile) |
| **Embeddings** | OpenAI text-embedding-3-large |
| **Vector DB** | Qdrant |
| **SQL DB** | PostgreSQL + TimescaleDB |
| **Backend** | FastAPI (Python 3.11+) |
| **Frontend** | Next.js 14 (React, TypeScript) |
| **Orchestration** | LangGraph v1 |
| **Infrastructure** | GCP (Compute Engine, Cloud SQL, Cloud Storage) |
| **Knowledge Graph** | Neo4j (Phase 2) |

---

## Documentation Structure

### Core Planning Documents

| # | Document | Description | Status |
|---|----------|-------------|--------|
| 01 | [Architecture Overview](./01-ARCHITECTURE.md) | System design, components, data flow | Pending |
| 02 | [Data Model](./02-DATA-MODEL.md) | Database schemas, vector collections, relationships | Pending |
| 03 | [Ingestion Pipeline](./03-INGESTION-PIPELINE.md) | Document collection, parsing, chunking, embedding | Pending |
| 04 | [Retrieval System](./04-RETRIEVAL-SYSTEM.md) | Hybrid search, reranking, query enhancement | Pending |
| 05 | [Agentic Workflow](./05-AGENTIC-WORKFLOW.md) | LangGraph nodes, state, edges, HITL | Pending |
| 06 | [API Specification](./06-API-SPECIFICATION.md) | REST endpoints, authentication, schemas | Pending |
| 07 | [Frontend Specification](./07-FRONTEND-SPEC.md) | Pages, components, UX flows | Pending |
| 08 | [Infrastructure](./08-INFRASTRUCTURE.md) | GCP setup, Docker, CI/CD | Pending |
| 09 | [Evaluation & Monitoring](./09-EVALUATION.md) | RAGAS metrics, LangSmith, observability | Pending |
| 10 | [Implementation Roadmap](./10-IMPLEMENTATION-ROADMAP.md) | Phases, milestones, dependencies | Pending |

### Reference Documents

| Document | Description |
|----------|-------------|
| [NIFTY 50 Companies](./ref/NIFTY50-COMPANIES.md) | Complete list with symbols, sectors |
| [Data Sources](./ref/DATA-SOURCES.md) | APIs, RSS feeds, scraping targets |
| [Prompt Templates](./ref/PROMPT-TEMPLATES.md) | All LLM prompts used in the system |
| [Environment Variables](./ref/ENV-VARIABLES.md) | Required configuration |

---

## Project Goals

### Primary Objectives
1. Answer any financial query about NIFTY 50 companies with source citations
2. Ingest and process all major document types (annual reports, quarterly results, news)
3. Maintain <24h data freshness for all document types
4. Achieve >90% retrieval recall on golden QA set
5. Maintain <2% hallucination rate

### Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Query Coverage | >90% of investor queries | Manual evaluation |
| Retrieval Recall | >90% | RAGAS on golden set |
| Hallucination Rate | <2% | RAGAS faithfulness |
| Response Latency | <10s (p95) | Prometheus metrics |
| Data Freshness | <24h | Ingestion timestamps |
| Uptime | 99.5% | GCP monitoring |

---

## Technology Stack Summary

### Backend Services
```
FastAPI          - REST API framework
LangGraph        - Agentic workflow orchestration
LangChain        - LLM abstractions and tools
LlamaIndex       - Document parsing and indexing
Celery + Redis   - Async task processing
SQLAlchemy       - ORM for PostgreSQL
Qdrant Client    - Vector database operations
Groq SDK         - LLM inference
```

### Frontend
```
Next.js 14       - React framework with App Router
TypeScript       - Type safety
Tailwind CSS     - Styling
shadcn/ui        - Component library
Recharts         - Data visualization
React Query      - Server state management
```

### Infrastructure
```
GCP Compute Engine  - Application hosting
GCP Cloud SQL       - PostgreSQL database
GCP Cloud Storage   - Document storage
Qdrant Cloud/Self   - Vector database
Redis               - Caching and job queue
Docker Compose      - Container orchestration
Terraform           - Infrastructure as code
GitHub Actions      - CI/CD
```

---

## Document Conventions

### Code Blocks
- Python code uses type hints
- All functions include docstrings
- Configuration uses environment variables

### Diagrams
- ASCII diagrams for text-based representation
- Mermaid syntax for flowcharts when applicable

### Status Indicators
- ✅ Complete
- 🚧 In Progress
- ⏳ Pending
- ❌ Blocked

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2024-11-25 | Initial documentation structure |

---

## How to Use These Documents

1. **Start with Architecture** (01) to understand the overall system
2. **Review Data Model** (02) for database and storage design
3. **Follow Ingestion → Retrieval → Agents** (03-05) for the RAG pipeline
4. **API and Frontend** (06-07) for application layer
5. **Infrastructure** (08) for deployment
6. **Evaluation** (09) for quality assurance
7. **Implementation Roadmap** (10) for execution plan

Each document is self-contained but references others where needed.

