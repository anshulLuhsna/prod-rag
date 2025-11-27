# MVP Implementation Guide: Banking & Finance RAG System

> **Note:** Documents for the 5 banks will be provided manually. This guide focuses on the technical implementation.

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Environment Setup](#2-environment-setup)
3. [Docker Compose Configuration](#3-docker-compose-configuration)
4. [Backend Implementation](#4-backend-implementation)
5. [Database Schema](#5-database-schema)
6. [Document Upload & Processing](#6-document-upload--processing)
7. [Ingestion Pipeline](#7-ingestion-pipeline)
8. [Retrieval System](#8-retrieval-system)
9. [Agentic Workflow (LangGraph)](#9-agentic-workflow-langgraph)
10. [API Endpoints](#10-api-endpoints)
11. [Frontend Implementation](#11-frontend-implementation)
12. [Testing & Evaluation](#12-testing--evaluation)
13. [Deployment Commands](#13-deployment-commands)

---

## 1. Project Structure

```
~/nifty50-rag/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                    # FastAPI application
│   │   ├── config.py                  # Configuration settings
│   │   ├── dependencies.py            # Dependency injection
│   │   │
│   │   ├── api/
│   │   │   ├── __init__.py
│   │   │   ├── routes/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── health.py          # Health check endpoints
│   │   │   │   ├── companies.py       # Company endpoints
│   │   │   │   ├── documents.py       # Document endpoints
│   │   │   │   ├── query.py           # RAG query endpoints
│   │   │   │   └── ingest.py          # Ingestion endpoints
│   │   │   └── schemas/
│   │   │       ├── __init__.py
│   │   │       ├── company.py
│   │   │       ├── document.py
│   │   │       └── query.py
│   │   │
│   │   ├── models/
│   │   │   ├── __init__.py
│   │   │   ├── company.py             # SQLAlchemy models
│   │   │   ├── document.py
│   │   │   └── fundamentals.py
│   │   │
│   │   ├── services/
│   │   │   ├── __init__.py
│   │   │   ├── company_service.py
│   │   │   ├── document_service.py
│   │   │   └── query_service.py
│   │   │
│   │   ├── ingestion/
│   │   │   ├── __init__.py
│   │   │   ├── parser.py              # LlamaParse integration
│   │   │   ├── chunker.py             # Document chunking
│   │   │   ├── embedder.py            # OpenAI embeddings
│   │   │   └── indexer.py             # Qdrant indexing
│   │   │
│   │   ├── retrieval/
│   │   │   ├── __init__.py
│   │   │   ├── vector_search.py       # Qdrant search
│   │   │   ├── bm25_search.py         # BM25 sparse search
│   │   │   ├── hybrid.py              # Hybrid search (RRF)
│   │   │   └── reranker.py            # CrossEncoder reranking
│   │   │
│   │   ├── agents/
│   │   │   ├── __init__.py
│   │   │   ├── state.py               # LangGraph state schema
│   │   │   ├── router.py              # Query router node
│   │   │   ├── retriever.py           # Retrieval node
│   │   │   ├── grader.py              # Document grader node
│   │   │   ├── generator.py           # Answer generation node
│   │   │   ├── fact_checker.py        # Hallucination check node
│   │   │   └── graph.py               # LangGraph workflow
│   │   │
│   │   └── db/
│   │       ├── __init__.py
│   │       ├── session.py             # Database session
│   │       └── seed.py                # Seed data
│   │
│   ├── workers/
│   │   ├── __init__.py
│   │   ├── celery_app.py              # Celery configuration
│   │   └── tasks.py                   # Celery tasks
│   │
│   ├── alembic/                       # Database migrations
│   │   ├── versions/
│   │   └── env.py
│   │
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── test_api.py
│   │   ├── test_retrieval.py
│   │   └── test_agents.py
│   │
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── alembic.ini
│   └── pyproject.toml
│
├── frontend/
│   ├── app/
│   │   ├── layout.tsx                 # Root layout
│   │   ├── page.tsx                   # Home page
│   │   ├── query/
│   │   │   └── page.tsx               # Q&A interface
│   │   ├── companies/
│   │   │   ├── page.tsx               # Company list
│   │   │   └── [symbol]/
│   │   │       └── page.tsx           # Company detail
│   │   └── admin/
│   │       └── ingest/
│   │           └── page.tsx           # Document upload
│   │
│   ├── components/
│   │   ├── ui/                        # shadcn/ui components
│   │   ├── QueryInput.tsx
│   │   ├── ResponseDisplay.tsx
│   │   ├── CitationCard.tsx
│   │   ├── CompanyCard.tsx
│   │   └── DocumentUpload.tsx
│   │
│   ├── lib/
│   │   ├── api.ts                     # API client
│   │   └── utils.ts
│   │
│   ├── Dockerfile
│   ├── package.json
│   ├── tailwind.config.ts
│   └── next.config.js
│
├── data/
│   ├── documents/                     # Raw PDF files (manual upload)
│   │   ├── HDFCBANK/
│   │   │   ├── annual_reports/
│   │   │   │   ├── FY2022.pdf
│   │   │   │   ├── FY2023.pdf
│   │   │   │   └── FY2024.pdf
│   │   │   └── quarterly_results/
│   │   │       ├── Q1FY23.pdf
│   │   │       ├── Q2FY23.pdf
│   │   │       └── ...
│   │   ├── ICICIBANK/
│   │   ├── SBIN/
│   │   ├── BAJFINANCE/
│   │   └── KOTAKBANK/
│   │
│   ├── processed/                     # Parsed documents
│   └── logs/                          # Application logs
│
├── docker-compose.yml
├── .env.example
├── .env                               # Local environment (gitignored)
├── .gitignore
└── README.md
```

---

## 2. Environment Setup

### Required API Keys

You'll need the following API keys:

| Service | Purpose | Get It From |
|---------|---------|-------------|
| **Groq** | LLM for generation | https://console.groq.com |
| **OpenAI** | Embeddings (text-embedding-3-large) | https://platform.openai.com |
| **LlamaParse** | PDF parsing | https://cloud.llamaindex.ai |

### Environment Variables

Create `.env` file in project root:

```env
# ===========================================
# NIFTY 50 RAG MVP - Environment Variables
# ===========================================

# ==================== API Keys ====================
GROQ_API_KEY=gsk_your_groq_api_key
OPENAI_API_KEY=sk-your_openai_api_key
LLAMAPARSE_API_KEY=llx-your_llamaparse_key

# ==================== Database ====================
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=nifty50
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=nifty50_rag

# Full connection string (for SQLAlchemy)
DATABASE_URL=postgresql+asyncpg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}

# ==================== Qdrant ====================
QDRANT_HOST=qdrant
QDRANT_PORT=6333
QDRANT_COLLECTION=nifty50_banking_mvp

# ==================== Redis ====================
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_URL=redis://${REDIS_HOST}:${REDIS_PORT}/0

# ==================== Application ====================
APP_ENV=development
DEBUG=true
LOG_LEVEL=INFO

# Backend
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8000

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:8000

# ==================== Model Configuration ====================
# LLM
LLM_MODEL=llama-3.3-70b-versatile
LLM_TEMPERATURE=0.1
LLM_MAX_TOKENS=4096

# Embeddings
EMBEDDING_MODEL=text-embedding-3-large
EMBEDDING_DIMENSION=3072

# ==================== Retrieval Configuration ====================
RETRIEVAL_TOP_K=10
RERANK_TOP_K=5
CHUNK_SIZE=512
CHUNK_OVERLAP=50

# ==================== Celery ====================
CELERY_BROKER_URL=redis://${REDIS_HOST}:${REDIS_PORT}/0
CELERY_RESULT_BACKEND=redis://${REDIS_HOST}:${REDIS_PORT}/1
```

---

## 3. Docker Compose Configuration

### `docker-compose.yml`

```yaml
version: '3.8'

services:
  # ==================== PostgreSQL ====================
  postgres:
    image: postgres:15-alpine
    container_name: nifty50-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ==================== Qdrant Vector DB ====================
  qdrant:
    image: qdrant/qdrant:latest
    container_name: nifty50-qdrant
    restart: unless-stopped
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - qdrant_data:/qdrant/storage
    environment:
      QDRANT__SERVICE__GRPC_PORT: 6334

  # ==================== Redis ====================
  redis:
    image: redis:7-alpine
    container_name: nifty50-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ==================== Backend (FastAPI) ====================
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: nifty50-backend
    restart: unless-stopped
    ports:
      - "8000:8000"
    volumes:
      - ./backend:/app
      - ./data:/app/data
    environment:
      - POSTGRES_HOST=postgres
      - QDRANT_HOST=qdrant
      - REDIS_HOST=redis
    env_file:
      - .env
    depends_on:
      postgres:
        condition: service_healthy
      qdrant:
        condition: service_started
      redis:
        condition: service_healthy
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

  # ==================== Celery Worker ====================
  celery-worker:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: nifty50-celery-worker
    restart: unless-stopped
    volumes:
      - ./backend:/app
      - ./data:/app/data
    environment:
      - POSTGRES_HOST=postgres
      - QDRANT_HOST=qdrant
      - REDIS_HOST=redis
    env_file:
      - .env
    depends_on:
      - redis
      - postgres
      - qdrant
    command: celery -A workers.celery_app worker --loglevel=info --concurrency=2

  # ==================== Frontend (Next.js) ====================
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: nifty50-frontend
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules
      - /app/.next
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:8000
    depends_on:
      - backend
    command: npm run dev

volumes:
  postgres_data:
  qdrant_data:
  redis_data:
```

---

## 4. Backend Implementation

### 4.1 Requirements (`backend/requirements.txt`)

```txt
# FastAPI & Server
fastapi==0.109.0
uvicorn[standard]==0.27.0
python-multipart==0.0.6

# Database
sqlalchemy[asyncio]==2.0.25
asyncpg==0.29.0
alembic==1.13.1

# Redis & Celery
redis==5.0.1
celery==5.3.6

# LangChain & LangGraph
langchain==0.1.4
langchain-community==0.0.16
langchain-openai==0.0.5
langgraph==0.0.20
langsmith==0.0.83

# Embeddings & Vector DB
openai==1.10.0
qdrant-client==1.7.0

# Document Processing
llama-parse==0.3.3
llama-index==0.10.10

# Search & Retrieval
rank-bm25==0.2.2
sentence-transformers==2.3.1

# AI/ML
groq==0.4.2

# Utilities
pydantic==2.5.3
pydantic-settings==2.1.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
httpx==0.26.0
tenacity==8.2.3
python-dotenv==1.0.0

# Data Processing
pandas==2.2.0
numpy==1.26.3
yfinance==0.2.35

# Testing
pytest==7.4.4
pytest-asyncio==0.23.3
```

### 4.2 Main Application (`backend/app/main.py`)

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.config import settings
from app.api.routes import health, companies, documents, query, ingest
from app.db.session import init_db

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await init_db()
    yield
    # Shutdown
    pass

app = FastAPI(
    title="NIFTY 50 RAG MVP",
    description="Banking & Finance Sector RAG System",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://frontend:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes
app.include_router(health.router, tags=["Health"])
app.include_router(companies.router, prefix="/api/companies", tags=["Companies"])
app.include_router(documents.router, prefix="/api/documents", tags=["Documents"])
app.include_router(query.router, prefix="/api/query", tags=["Query"])
app.include_router(ingest.router, prefix="/api/ingest", tags=["Ingestion"])
```

### 4.3 Configuration (`backend/app/config.py`)

```python
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    # Database
    postgres_host: str = "localhost"
    postgres_port: int = 5432
    postgres_user: str = "nifty50"
    postgres_password: str = ""
    postgres_db: str = "nifty50_rag"
    
    @property
    def database_url(self) -> str:
        return f"postgresql+asyncpg://{self.postgres_user}:{self.postgres_password}@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
    
    # Qdrant
    qdrant_host: str = "localhost"
    qdrant_port: int = 6333
    qdrant_collection: str = "nifty50_banking_mvp"
    
    # Redis
    redis_host: str = "localhost"
    redis_port: int = 6379
    
    # API Keys
    groq_api_key: str = ""
    openai_api_key: str = ""
    llamaparse_api_key: str = ""
    
    # Model Config
    llm_model: str = "llama-3.3-70b-versatile"
    embedding_model: str = "text-embedding-3-large"
    embedding_dimension: int = 3072
    
    # Retrieval Config
    retrieval_top_k: int = 10
    rerank_top_k: int = 5
    chunk_size: int = 512
    chunk_overlap: int = 50
    
    class Config:
        env_file = ".env"

@lru_cache()
def get_settings() -> Settings:
    return Settings()

settings = get_settings()
```

---

## 5. Database Schema

### 5.1 SQLAlchemy Models

#### `backend/app/models/company.py`

```python
from sqlalchemy import Column, Integer, String, Float, DateTime, Enum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum

from app.db.session import Base

class SectorType(enum.Enum):
    PRIVATE_BANK = "private_bank"
    PUBLIC_BANK = "public_bank"
    NBFC = "nbfc"

class Company(Base):
    __tablename__ = "companies"
    
    id = Column(Integer, primary_key=True, index=True)
    symbol = Column(String(20), unique=True, nullable=False, index=True)
    name = Column(String(200), nullable=False)
    sector = Column(Enum(SectorType), nullable=False)
    market_cap_rank = Column(Integer)
    
    # Metadata
    ir_page_url = Column(String(500))
    nse_symbol = Column(String(20))
    bse_code = Column(String(10))
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    documents = relationship("Document", back_populates="company")
    fundamentals = relationship("Fundamental", back_populates="company")
```

#### `backend/app/models/document.py`

```python
from sqlalchemy import Column, Integer, String, Text, DateTime, Enum, ForeignKey, JSON
from sqlalchemy.orm import relationship
from datetime import datetime
import enum

from app.db.session import Base

class DocumentType(enum.Enum):
    ANNUAL_REPORT = "annual_report"
    QUARTERLY_RESULT = "quarterly_result"
    INVESTOR_PRESENTATION = "investor_presentation"
    NEWS = "news"

class ProcessingStatus(enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

class Document(Base):
    __tablename__ = "documents"
    
    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    
    # Document info
    doc_type = Column(Enum(DocumentType), nullable=False)
    fiscal_year = Column(String(10))  # e.g., "FY2024"
    fiscal_quarter = Column(String(10))  # e.g., "Q1", "Q2"
    title = Column(String(500))
    
    # File info
    file_path = Column(String(500), nullable=False)
    file_hash = Column(String(64), unique=True)  # SHA-256
    file_size = Column(Integer)  # bytes
    page_count = Column(Integer)
    
    # Processing
    status = Column(Enum(ProcessingStatus), default=ProcessingStatus.PENDING)
    chunk_count = Column(Integer, default=0)
    error_message = Column(Text)
    
    # Metadata
    metadata = Column(JSON, default={})
    
    created_at = Column(DateTime, default=datetime.utcnow)
    processed_at = Column(DateTime)
    
    # Relationships
    company = relationship("Company", back_populates="documents")
```

#### `backend/app/models/fundamentals.py`

```python
from sqlalchemy import Column, Integer, String, Float, DateTime, Date, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime

from app.db.session import Base

class Fundamental(Base):
    __tablename__ = "fundamentals"
    
    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    
    # Period
    period = Column(String(10), nullable=False)  # e.g., "Q1FY24", "FY2024"
    period_end_date = Column(Date)
    
    # Key Metrics
    revenue = Column(Float)
    net_income = Column(Float)
    eps = Column(Float)
    book_value = Column(Float)
    
    # Ratios
    pe_ratio = Column(Float)
    pb_ratio = Column(Float)
    roe = Column(Float)  # Return on Equity
    roa = Column(Float)  # Return on Assets
    
    # Banking Specific
    net_interest_margin = Column(Float)
    gross_npa = Column(Float)
    net_npa = Column(Float)
    casa_ratio = Column(Float)
    capital_adequacy_ratio = Column(Float)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    company = relationship("Company", back_populates="fundamentals")
```

### 5.2 Seed Data (`backend/app/db/seed.py`)

```python
from app.models.company import Company, SectorType
from app.db.session import async_session

MVP_COMPANIES = [
    {
        "symbol": "HDFCBANK",
        "name": "HDFC Bank Ltd",
        "sector": SectorType.PRIVATE_BANK,
        "market_cap_rank": 3,
        "nse_symbol": "HDFCBANK",
        "bse_code": "500180",
        "ir_page_url": "https://www.hdfcbank.com/personal/about-us/investor-relations"
    },
    {
        "symbol": "ICICIBANK",
        "name": "ICICI Bank Ltd",
        "sector": SectorType.PRIVATE_BANK,
        "market_cap_rank": 5,
        "nse_symbol": "ICICIBANK",
        "bse_code": "532174",
        "ir_page_url": "https://www.icicibank.com/about-us/investor-relations"
    },
    {
        "symbol": "SBIN",
        "name": "State Bank of India",
        "sector": SectorType.PUBLIC_BANK,
        "market_cap_rank": 9,
        "nse_symbol": "SBIN",
        "bse_code": "500112",
        "ir_page_url": "https://sbi.co.in/web/investor-relations/annual-report"
    },
    {
        "symbol": "BAJFINANCE",
        "name": "Bajaj Finance Ltd",
        "sector": SectorType.NBFC,
        "market_cap_rank": 13,
        "nse_symbol": "BAJFINANCE",
        "bse_code": "500034",
        "ir_page_url": "https://www.bajajfinserv.in/investor-relations"
    },
    {
        "symbol": "KOTAKBANK",
        "name": "Kotak Mahindra Bank Ltd",
        "sector": SectorType.PRIVATE_BANK,
        "market_cap_rank": 10,
        "nse_symbol": "KOTAKBANK",
        "bse_code": "500247",
        "ir_page_url": "https://www.kotak.com/en/investor-relations.html"
    },
]

async def seed_companies():
    async with async_session() as session:
        for company_data in MVP_COMPANIES:
            company = Company(**company_data)
            session.add(company)
        await session.commit()
```

---

## 6. Document Upload & Processing

### 6.1 Document Folder Structure

Organize your manually downloaded documents as follows:

```
data/documents/
├── HDFCBANK/
│   ├── annual_reports/
│   │   ├── HDFCBANK_AR_FY2022.pdf
│   │   ├── HDFCBANK_AR_FY2023.pdf
│   │   └── HDFCBANK_AR_FY2024.pdf
│   └── quarterly_results/
│       ├── HDFCBANK_Q1_FY2023.pdf
│       ├── HDFCBANK_Q2_FY2023.pdf
│       ├── HDFCBANK_Q3_FY2023.pdf
│       ├── HDFCBANK_Q4_FY2023.pdf
│       ├── HDFCBANK_Q1_FY2024.pdf
│       ├── HDFCBANK_Q2_FY2024.pdf
│       ├── HDFCBANK_Q3_FY2024.pdf
│       └── HDFCBANK_Q4_FY2024.pdf
│
├── ICICIBANK/
│   ├── annual_reports/
│   │   └── ... (same structure)
│   └── quarterly_results/
│       └── ...
│
├── SBIN/
│   └── ...
│
├── BAJFINANCE/
│   └── ...
│
└── KOTAKBANK/
    └── ...
```

### 6.2 Naming Convention

| Document Type | Pattern | Example |
|--------------|---------|---------|
| Annual Report | `{SYMBOL}_AR_{FYXXXX}.pdf` | `HDFCBANK_AR_FY2024.pdf` |
| Quarterly Result | `{SYMBOL}_{QX}_{FYXXXX}.pdf` | `HDFCBANK_Q1_FY2024.pdf` |

### 6.3 Document Checklist

| Company | Annual Reports | Quarterly Results | Total |
|---------|----------------|-------------------|-------|
| HDFCBANK | 3 (FY22, FY23, FY24) | 8 (Q1-Q4 × 2 years) | 11 |
| ICICIBANK | 3 | 8 | 11 |
| SBIN | 3 | 8 | 11 |
| BAJFINANCE | 3 | 8 | 11 |
| KOTAKBANK | 3 | 8 | 11 |
| **Total** | **15** | **40** | **55** |

---

## 7. Ingestion Pipeline

### 7.1 LlamaParse Integration (`backend/app/ingestion/parser.py`)

```python
from llama_parse import LlamaParse
from llama_index.core import Document
import hashlib
from pathlib import Path
from typing import List

from app.config import settings

class DocumentParser:
    def __init__(self):
        self.parser = LlamaParse(
            api_key=settings.llamaparse_api_key,
            result_type="markdown",
            num_workers=4,
            verbose=True,
            language="en",
            # Table extraction settings
            do_not_cache=False,
            skip_diagonal_text=True,
            do_not_unroll_columns=False,
        )
    
    async def parse_pdf(self, file_path: str) -> dict:
        """Parse a PDF file and return structured content."""
        path = Path(file_path)
        
        # Calculate file hash for deduplication
        file_hash = self._calculate_hash(path)
        
        # Parse document
        documents = await self.parser.aload_data(str(path))
        
        # Extract content
        content = "\n\n".join([doc.text for doc in documents])
        
        # Extract metadata
        metadata = {
            "file_name": path.name,
            "file_hash": file_hash,
            "page_count": len(documents),
            "total_chars": len(content),
        }
        
        return {
            "content": content,
            "documents": documents,
            "metadata": metadata,
        }
    
    def _calculate_hash(self, path: Path) -> str:
        """Calculate SHA-256 hash of file."""
        sha256_hash = hashlib.sha256()
        with open(path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()
```

### 7.2 Chunking Strategy (`backend/app/ingestion/chunker.py`)

```python
from llama_index.core.node_parser import (
    SentenceSplitter,
    HierarchicalNodeParser,
)
from llama_index.core import Document
from typing import List

from app.config import settings

class DocumentChunker:
    def __init__(self):
        # Hierarchical chunking: parent (1024) -> child (512)
        self.hierarchical_parser = HierarchicalNodeParser.from_defaults(
            chunk_sizes=[1024, 512],
            chunk_overlap=50,
        )
        
        # Simple sentence splitter for fallback
        self.sentence_splitter = SentenceSplitter(
            chunk_size=settings.chunk_size,
            chunk_overlap=settings.chunk_overlap,
        )
    
    def chunk_document(
        self,
        content: str,
        metadata: dict,
        strategy: str = "hierarchical"
    ) -> List[dict]:
        """Chunk document content with metadata."""
        
        doc = Document(text=content, metadata=metadata)
        
        if strategy == "hierarchical":
            nodes = self.hierarchical_parser.get_nodes_from_documents([doc])
        else:
            nodes = self.sentence_splitter.get_nodes_from_documents([doc])
        
        chunks = []
        for i, node in enumerate(nodes):
            chunk = {
                "id": f"{metadata.get('file_hash', 'unknown')}_{i}",
                "text": node.text,
                "metadata": {
                    **metadata,
                    "chunk_index": i,
                    "chunk_size": len(node.text),
                    "parent_id": getattr(node, 'parent_node', {}).get('node_id') if hasattr(node, 'parent_node') else None,
                },
            }
            chunks.append(chunk)
        
        return chunks
```

### 7.3 Embedding Service (`backend/app/ingestion/embedder.py`)

```python
from openai import OpenAI
from typing import List
import numpy as np
from tenacity import retry, stop_after_attempt, wait_exponential
import redis

from app.config import settings

class EmbeddingService:
    def __init__(self):
        self.client = OpenAI(api_key=settings.openai_api_key)
        self.model = settings.embedding_model
        self.dimension = settings.embedding_dimension
        self.cache = redis.Redis(
            host=settings.redis_host,
            port=settings.redis_port,
            db=2  # Use separate DB for embedding cache
        )
    
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    def embed_texts(self, texts: List[str]) -> List[List[float]]:
        """Embed multiple texts with caching."""
        embeddings = []
        texts_to_embed = []
        indices_to_embed = []
        
        # Check cache first
        for i, text in enumerate(texts):
            cache_key = f"emb:{hash(text)}"
            cached = self.cache.get(cache_key)
            if cached:
                embeddings.append(np.frombuffer(cached, dtype=np.float32).tolist())
            else:
                embeddings.append(None)
                texts_to_embed.append(text)
                indices_to_embed.append(i)
        
        # Embed uncached texts
        if texts_to_embed:
            response = self.client.embeddings.create(
                model=self.model,
                input=texts_to_embed,
            )
            
            for idx, emb_data in zip(indices_to_embed, response.data):
                emb = emb_data.embedding
                embeddings[idx] = emb
                
                # Cache the embedding
                cache_key = f"emb:{hash(texts[idx])}"
                self.cache.set(cache_key, np.array(emb, dtype=np.float32).tobytes())
        
        return embeddings
    
    def embed_query(self, query: str) -> List[float]:
        """Embed a single query."""
        return self.embed_texts([query])[0]
```

### 7.4 Qdrant Indexer (`backend/app/ingestion/indexer.py`)

```python
from qdrant_client import QdrantClient
from qdrant_client.models import (
    VectorParams, Distance, PointStruct,
    Filter, FieldCondition, MatchValue,
)
from typing import List, Optional
import uuid

from app.config import settings

class QdrantIndexer:
    def __init__(self):
        self.client = QdrantClient(
            host=settings.qdrant_host,
            port=settings.qdrant_port,
        )
        self.collection_name = settings.qdrant_collection
        self._ensure_collection()
    
    def _ensure_collection(self):
        """Create collection if it doesn't exist."""
        collections = self.client.get_collections().collections
        exists = any(c.name == self.collection_name for c in collections)
        
        if not exists:
            self.client.create_collection(
                collection_name=self.collection_name,
                vectors_config=VectorParams(
                    size=settings.embedding_dimension,
                    distance=Distance.COSINE,
                ),
            )
    
    def index_chunks(
        self,
        chunks: List[dict],
        embeddings: List[List[float]],
    ) -> int:
        """Index chunks with their embeddings."""
        points = []
        for chunk, embedding in zip(chunks, embeddings):
            point = PointStruct(
                id=str(uuid.uuid4()),
                vector=embedding,
                payload={
                    "text": chunk["text"],
                    "chunk_id": chunk["id"],
                    **chunk["metadata"],
                },
            )
            points.append(point)
        
        # Batch upsert
        self.client.upsert(
            collection_name=self.collection_name,
            points=points,
        )
        
        return len(points)
    
    def search(
        self,
        query_vector: List[float],
        top_k: int = 10,
        filters: Optional[dict] = None,
    ) -> List[dict]:
        """Search for similar vectors."""
        filter_conditions = None
        if filters:
            conditions = []
            for key, value in filters.items():
                conditions.append(
                    FieldCondition(key=key, match=MatchValue(value=value))
                )
            filter_conditions = Filter(must=conditions)
        
        results = self.client.search(
            collection_name=self.collection_name,
            query_vector=query_vector,
            limit=top_k,
            query_filter=filter_conditions,
        )
        
        return [
            {
                "id": r.id,
                "score": r.score,
                "text": r.payload.get("text"),
                "metadata": {k: v for k, v in r.payload.items() if k != "text"},
            }
            for r in results
        ]
```

---

## 8. Retrieval System

### 8.1 Hybrid Search (`backend/app/retrieval/hybrid.py`)

```python
from typing import List, Optional
from rank_bm25 import BM25Okapi
import numpy as np

from app.ingestion.embedder import EmbeddingService
from app.ingestion.indexer import QdrantIndexer

class HybridRetriever:
    def __init__(self):
        self.embedder = EmbeddingService()
        self.indexer = QdrantIndexer()
        self.bm25_index = None
        self.bm25_docs = []
    
    def build_bm25_index(self, documents: List[dict]):
        """Build BM25 index from documents."""
        self.bm25_docs = documents
        tokenized = [doc["text"].lower().split() for doc in documents]
        self.bm25_index = BM25Okapi(tokenized)
    
    def search(
        self,
        query: str,
        top_k: int = 10,
        filters: Optional[dict] = None,
        vector_weight: float = 0.6,
    ) -> List[dict]:
        """Hybrid search with RRF fusion."""
        
        # Vector search
        query_vector = self.embedder.embed_query(query)
        vector_results = self.indexer.search(query_vector, top_k * 2, filters)
        
        # BM25 search (if index exists)
        bm25_results = []
        if self.bm25_index:
            tokenized_query = query.lower().split()
            scores = self.bm25_index.get_scores(tokenized_query)
            top_indices = np.argsort(scores)[::-1][:top_k * 2]
            bm25_results = [
                {"id": i, "score": scores[i], **self.bm25_docs[i]}
                for i in top_indices if scores[i] > 0
            ]
        
        # RRF Fusion
        fused = self._rrf_fusion(
            vector_results,
            bm25_results,
            vector_weight=vector_weight,
            k=60,
        )
        
        return fused[:top_k]
    
    def _rrf_fusion(
        self,
        vector_results: List[dict],
        bm25_results: List[dict],
        vector_weight: float = 0.6,
        k: int = 60,
    ) -> List[dict]:
        """Reciprocal Rank Fusion."""
        scores = {}
        docs = {}
        
        # Vector scores
        for rank, doc in enumerate(vector_results):
            doc_id = doc.get("chunk_id", doc.get("id"))
            rrf_score = vector_weight / (k + rank + 1)
            scores[doc_id] = scores.get(doc_id, 0) + rrf_score
            docs[doc_id] = doc
        
        # BM25 scores
        bm25_weight = 1 - vector_weight
        for rank, doc in enumerate(bm25_results):
            doc_id = doc.get("chunk_id", doc.get("id"))
            rrf_score = bm25_weight / (k + rank + 1)
            scores[doc_id] = scores.get(doc_id, 0) + rrf_score
            if doc_id not in docs:
                docs[doc_id] = doc
        
        # Sort by fused score
        sorted_ids = sorted(scores.keys(), key=lambda x: scores[x], reverse=True)
        return [{"rrf_score": scores[id], **docs[id]} for id in sorted_ids]
```

### 8.2 Reranker (`backend/app/retrieval/reranker.py`)

```python
from sentence_transformers import CrossEncoder
from typing import List

class Reranker:
    def __init__(self, model_name: str = "cross-encoder/ms-marco-MiniLM-L-6-v2"):
        self.model = CrossEncoder(model_name)
    
    def rerank(
        self,
        query: str,
        documents: List[dict],
        top_k: int = 5,
    ) -> List[dict]:
        """Rerank documents using cross-encoder."""
        if not documents:
            return []
        
        # Prepare pairs
        pairs = [(query, doc["text"]) for doc in documents]
        
        # Score
        scores = self.model.predict(pairs)
        
        # Combine with documents
        for doc, score in zip(documents, scores):
            doc["rerank_score"] = float(score)
        
        # Sort and return top_k
        sorted_docs = sorted(documents, key=lambda x: x["rerank_score"], reverse=True)
        return sorted_docs[:top_k]
```

---

## 9. Agentic Workflow (LangGraph)

### 9.1 State Schema (`backend/app/agents/state.py`)

```python
from typing import TypedDict, List, Optional, Literal
from langchain_core.messages import BaseMessage

class DocumentGrade(TypedDict):
    doc_id: str
    relevant: bool
    score: float

class Citation(TypedDict):
    doc_id: str
    company: str
    doc_type: str
    fiscal_period: str
    excerpt: str

class AgenticRAGState(TypedDict):
    # Input
    query: str
    messages: List[BaseMessage]
    
    # Analysis
    query_type: Literal["factual", "comparative", "analytical", "trend"]
    companies_mentioned: List[str]
    
    # Retrieval
    retrieved_documents: List[dict]
    document_grades: List[DocumentGrade]
    relevant_documents: List[dict]
    
    # Generation
    rewrite_count: int
    generation_attempt: int
    response: Optional[str]
    citations: List[Citation]
    
    # Verification
    fact_check_passed: bool
    hallucination_detected: bool
    
    # Control
    next_action: Literal["retrieve", "rewrite", "generate", "fact_check", "respond", "end"]
```

### 9.2 LangGraph Workflow (`backend/app/agents/graph.py`)

```python
from langgraph.graph import StateGraph, END
from langchain_groq import ChatGroq

from app.agents.state import AgenticRAGState
from app.agents.router import route_query
from app.agents.retriever import retrieve_documents
from app.agents.grader import grade_documents
from app.agents.generator import generate_response
from app.agents.fact_checker import fact_check
from app.config import settings

def create_rag_workflow():
    """Create the agentic RAG workflow."""
    
    # Initialize LLM
    llm = ChatGroq(
        api_key=settings.groq_api_key,
        model=settings.llm_model,
        temperature=0.1,
    )
    
    # Create graph
    workflow = StateGraph(AgenticRAGState)
    
    # Add nodes
    workflow.add_node("router", lambda state: route_query(state, llm))
    workflow.add_node("retrieve", retrieve_documents)
    workflow.add_node("grade", lambda state: grade_documents(state, llm))
    workflow.add_node("rewrite", lambda state: rewrite_query(state, llm))
    workflow.add_node("generate", lambda state: generate_response(state, llm))
    workflow.add_node("fact_check", lambda state: fact_check(state, llm))
    
    # Entry point
    workflow.set_entry_point("router")
    
    # Conditional edges from router
    workflow.add_conditional_edges(
        "router",
        lambda state: state["next_action"],
        {
            "retrieve": "retrieve",
            "respond": END,
        }
    )
    
    # After retrieval -> grade
    workflow.add_edge("retrieve", "grade")
    
    # After grading -> generate or rewrite
    workflow.add_conditional_edges(
        "grade",
        lambda state: "rewrite" if not state["relevant_documents"] and state["rewrite_count"] < 2 else "generate",
        {
            "rewrite": "rewrite",
            "generate": "generate",
        }
    )
    
    # After rewrite -> retrieve again
    workflow.add_edge("rewrite", "retrieve")
    
    # After generation -> fact check
    workflow.add_edge("generate", "fact_check")
    
    # After fact check -> end or regenerate
    workflow.add_conditional_edges(
        "fact_check",
        lambda state: "generate" if state["hallucination_detected"] and state["generation_attempt"] < 2 else END,
        {
            "generate": "generate",
            END: END,
        }
    )
    
    return workflow.compile()

# Global workflow instance
rag_workflow = create_rag_workflow()
```

---

## 10. API Endpoints

### 10.1 Query Endpoint (`backend/app/api/routes/query.py`)

```python
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional, List
import json

from app.agents.graph import rag_workflow
from app.agents.state import AgenticRAGState

router = APIRouter()

class QueryRequest(BaseModel):
    query: str
    companies: Optional[List[str]] = None
    stream: bool = False

class QueryResponse(BaseModel):
    query: str
    response: str
    citations: List[dict]
    query_type: str
    retrieval_count: int

@router.post("/", response_model=QueryResponse)
async def submit_query(request: QueryRequest):
    """Submit a RAG query."""
    
    # Initialize state
    initial_state: AgenticRAGState = {
        "query": request.query,
        "messages": [],
        "query_type": "factual",
        "companies_mentioned": request.companies or [],
        "retrieved_documents": [],
        "document_grades": [],
        "relevant_documents": [],
        "rewrite_count": 0,
        "generation_attempt": 0,
        "response": None,
        "citations": [],
        "fact_check_passed": False,
        "hallucination_detected": False,
        "next_action": "retrieve",
    }
    
    # Run workflow
    final_state = await rag_workflow.ainvoke(initial_state)
    
    return QueryResponse(
        query=request.query,
        response=final_state.get("response", "Unable to generate response."),
        citations=final_state.get("citations", []),
        query_type=final_state.get("query_type", "unknown"),
        retrieval_count=len(final_state.get("relevant_documents", [])),
    )

@router.post("/stream")
async def stream_query(request: QueryRequest):
    """Stream a RAG query response."""
    
    async def generate():
        # Initial state
        state = {
            "query": request.query,
            # ... same as above
        }
        
        # Stream workflow execution
        async for event in rag_workflow.astream(state):
            yield f"data: {json.dumps(event)}\n\n"
    
    return StreamingResponse(
        generate(),
        media_type="text/event-stream"
    )
```

---

## 11. Frontend Implementation

### 11.1 Query Page (`frontend/app/query/page.tsx`)

```tsx
'use client';

import { useState } from 'react';
import { QueryInput } from '@/components/QueryInput';
import { ResponseDisplay } from '@/components/ResponseDisplay';
import { CitationCard } from '@/components/CitationCard';

interface QueryResponse {
  query: string;
  response: string;
  citations: Array<{
    doc_id: string;
    company: string;
    doc_type: string;
    fiscal_period: string;
    excerpt: string;
  }>;
  query_type: string;
  retrieval_count: number;
}

export default function QueryPage() {
  const [loading, setLoading] = useState(false);
  const [response, setResponse] = useState<QueryResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleQuery = async (query: string) => {
    setLoading(true);
    setError(null);
    
    try {
      const res = await fetch('/api/query', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query }),
      });
      
      if (!res.ok) throw new Error('Query failed');
      
      const data = await res.json();
      setResponse(data);
    } catch (err) {
      setError('Failed to process query. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
      <h1 className="text-3xl font-bold mb-8">
        Banking & Finance RAG
      </h1>
      
      <QueryInput onSubmit={handleQuery} loading={loading} />
      
      {error && (
        <div className="mt-4 p-4 bg-red-100 text-red-700 rounded">
          {error}
        </div>
      )}
      
      {response && (
        <div className="mt-8 space-y-6">
          <ResponseDisplay
            response={response.response}
            queryType={response.query_type}
          />
          
          {response.citations.length > 0 && (
            <div>
              <h3 className="text-lg font-semibold mb-3">Sources</h3>
              <div className="space-y-2">
                {response.citations.map((citation, i) => (
                  <CitationCard key={i} citation={citation} />
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
```

---

## 12. Testing & Evaluation

### 12.1 Golden QA Pairs

```json
[
  {
    "id": "1",
    "query": "What was HDFC Bank's revenue in FY2024?",
    "expected_answer_contains": ["revenue", "HDFC", "FY2024"],
    "expected_company": "HDFCBANK",
    "query_type": "factual"
  },
  {
    "id": "2",
    "query": "Compare HDFC Bank and ICICI Bank's net interest margins",
    "expected_answer_contains": ["NIM", "HDFC", "ICICI"],
    "expected_companies": ["HDFCBANK", "ICICIBANK"],
    "query_type": "comparative"
  },
  // ... more test cases
]
```

### 12.2 Evaluation Script

```python
from ragas import evaluate
from ragas.metrics import (
    context_precision,
    context_recall,
    faithfulness,
    answer_relevancy,
)

def evaluate_rag_system(test_cases: List[dict]):
    """Evaluate RAG system with RAGAS metrics."""
    
    results = []
    for case in test_cases:
        # Run query
        response = rag_workflow.invoke({"query": case["query"]})
        
        results.append({
            "question": case["query"],
            "answer": response["response"],
            "contexts": [d["text"] for d in response["relevant_documents"]],
            "ground_truth": case.get("expected_answer", ""),
        })
    
    # Calculate metrics
    metrics = evaluate(
        results,
        metrics=[
            context_precision,
            context_recall,
            faithfulness,
            answer_relevancy,
        ],
    )
    
    return metrics
```

---

## 13. Deployment Commands

### Initial Setup

```bash
# 1. Navigate to project directory
cd ~/nifty50-rag

# 2. Copy environment file
cp .env.example .env
# Edit .env with your API keys

# 3. Create data directories
mkdir -p data/documents/{HDFCBANK,ICICIBANK,SBIN,BAJFINANCE,KOTAKBANK}/{annual_reports,quarterly_results}
mkdir -p data/processed data/logs

# 4. Start services
docker compose up -d

# 5. Check services are running
docker compose ps

# 6. Run database migrations
docker compose exec backend alembic upgrade head

# 7. Seed company data
docker compose exec backend python -c "from app.db.seed import seed_companies; import asyncio; asyncio.run(seed_companies())"

# 8. Verify
curl http://localhost:8000/health
curl http://localhost:8000/api/companies
```

### Document Ingestion

```bash
# After placing documents in data/documents/...

# 1. Run ingestion for all documents
docker compose exec backend python -c "
from app.ingestion.pipeline import ingest_all_documents
import asyncio
asyncio.run(ingest_all_documents())
"

# 2. Or use Celery task
docker compose exec celery-worker celery -A workers.celery_app call tasks.ingest_all

# 3. Monitor progress
docker compose logs -f celery-worker

# 4. Verify indexed documents
curl http://localhost:8000/api/documents
```

### Testing

```bash
# Run tests
docker compose exec backend pytest tests/ -v

# Test a query
curl -X POST http://localhost:8000/api/query \
  -H "Content-Type: application/json" \
  -d '{"query": "What was HDFC Bank revenue in FY2024?"}'
```

### Useful Commands

```bash
# View logs
docker compose logs -f backend
docker compose logs -f celery-worker

# Restart services
docker compose restart backend
docker compose restart celery-worker

# Stop all services
docker compose down

# Stop and remove volumes (CAUTION: deletes data)
docker compose down -v

# Rebuild after code changes
docker compose build backend
docker compose up -d backend

# Enter container shell
docker compose exec backend bash
docker compose exec postgres psql -U nifty50 -d nifty50_rag

# Check Qdrant collections
curl http://localhost:6333/collections
```

---

## Quick Reference

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/companies` | List all companies |
| GET | `/api/companies/{symbol}` | Get company details |
| GET | `/api/documents` | List all documents |
| POST | `/api/ingest` | Trigger document ingestion |
| POST | `/api/query` | Submit RAG query |
| POST | `/api/query/stream` | Stream RAG response |

### Environment Variables Quick Reference

| Variable | Purpose |
|----------|---------|
| `GROQ_API_KEY` | LLM for generation |
| `OPENAI_API_KEY` | Embeddings |
| `LLAMAPARSE_API_KEY` | PDF parsing |
| `DATABASE_URL` | PostgreSQL connection |
| `QDRANT_HOST` | Vector DB host |
| `REDIS_HOST` | Cache/queue host |

---

*This guide provides complete implementation details for the Banking & Finance RAG MVP. Follow the phases sequentially for best results.*

