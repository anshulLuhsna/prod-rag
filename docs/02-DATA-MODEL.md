# 02 - Data Model

## Overview

This document defines all data structures used in the NIFTY 50 Agentic RAG system:
- PostgreSQL relational schemas
- Qdrant vector collection schemas
- Pydantic models for API
- LangGraph state schemas

---

## PostgreSQL Database Schema

### Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│    companies    │       │  fundamentals   │       │     prices      │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ id (PK)         │◄──────│ company_id (FK) │       │ id (PK)         │
│ symbol          │       │ id (PK)         │       │ company_id (FK) │◄┐
│ name            │       │ period          │       │ date            │ │
│ sector          │       │ period_type     │       │ open            │ │
│ industry        │       │ revenue         │       │ high            │ │
│ market_cap_rank │       │ net_income      │       │ low             │ │
│ isin            │       │ eps             │       │ close           │ │
│ created_at      │       │ pe_ratio        │       │ volume          │ │
│ updated_at      │       │ ...             │       │ created_at      │ │
└─────────────────┘       └─────────────────┘       └─────────────────┘ │
        │                                                               │
        │         ┌─────────────────┐       ┌─────────────────┐        │
        │         │    documents    │       │  ingestion_logs │        │
        │         ├─────────────────┤       ├─────────────────┤        │
        └────────►│ company_id (FK) │       │ document_id (FK)│◄───────┤
                  │ id (PK)         │◄──────│ id (PK)         │        │
                  │ doc_type        │       │ step            │        │
                  │ title           │       │ status          │        │
                  │ source_url      │       │ error_message   │        │
                  │ storage_path    │       │ created_at      │        │
                  │ content_hash    │       └─────────────────┘        │
                  │ fiscal_period   │                                   │
                  │ status          │       ┌─────────────────┐        │
                  │ chunk_count     │       │     queries     │        │
                  │ created_at      │       ├─────────────────┤        │
                  └─────────────────┘       │ id (PK)         │        │
                                            │ user_id (FK)    │        │
        ┌─────────────────┐                 │ question        │        │
        │      users      │                 │ response        │        │
        ├─────────────────┤                 │ citations       │        │
        │ id (PK)         │◄────────────────│ status          │        │
        │ email           │                 │ latency_ms      │        │
        │ hashed_password │                 │ token_count     │        │
        │ role            │                 │ created_at      │        │
        │ created_at      │                 └─────────────────┘        │
        └─────────────────┘                                            │
                                            ┌─────────────────┐        │
                                            │   news_articles │        │
                                            ├─────────────────┤        │
                                            │ id (PK)         │        │
                                            │ company_id (FK) │────────┘
                                            │ title           │
                                            │ source          │
                                            │ url             │
                                            │ summary         │
                                            │ sentiment       │
                                            │ published_at    │
                                            │ created_at      │
                                            └─────────────────┘
```

---

### Table Definitions

#### `companies`

Master table for NIFTY 50 companies.

```sql
CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) UNIQUE NOT NULL,        -- e.g., 'RELIANCE.NS'
    name VARCHAR(200) NOT NULL,                -- e.g., 'Reliance Industries Ltd'
    sector VARCHAR(100),                       -- e.g., 'Energy'
    industry VARCHAR(100),                     -- e.g., 'Oil & Gas Refining'
    market_cap_rank INTEGER,                   -- 1-50
    isin VARCHAR(20),                          -- e.g., 'INE002A01018'
    nse_symbol VARCHAR(20),                    -- e.g., 'RELIANCE'
    bse_code VARCHAR(10),                      -- e.g., '500325'
    website VARCHAR(255),
    ir_page_url VARCHAR(255),                  -- Investor relations page
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_companies_symbol ON companies(symbol);
CREATE INDEX idx_companies_sector ON companies(sector);
```

#### `fundamentals`

Quarterly and annual financial metrics.

```sql
CREATE TABLE fundamentals (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
    period VARCHAR(20) NOT NULL,               -- e.g., 'Q3FY24', 'FY2024'
    period_type VARCHAR(10) NOT NULL,          -- 'quarterly' or 'annual'
    period_end_date DATE,
    
    -- Income Statement
    revenue BIGINT,                            -- Total revenue (INR)
    operating_income BIGINT,
    net_income BIGINT,
    ebitda BIGINT,
    
    -- Per Share
    eps DECIMAL(10, 2),                        -- Earnings per share
    dps DECIMAL(10, 2),                        -- Dividend per share
    book_value_per_share DECIMAL(10, 2),
    
    -- Ratios
    pe_ratio DECIMAL(10, 2),
    pb_ratio DECIMAL(10, 2),
    roe DECIMAL(10, 4),                        -- Return on equity (decimal)
    roa DECIMAL(10, 4),                        -- Return on assets
    roce DECIMAL(10, 4),                       -- Return on capital employed
    debt_to_equity DECIMAL(10, 4),
    current_ratio DECIMAL(10, 4),
    
    -- Balance Sheet
    total_assets BIGINT,
    total_liabilities BIGINT,
    total_equity BIGINT,
    total_debt BIGINT,
    cash_and_equivalents BIGINT,
    
    -- Market
    market_cap BIGINT,
    enterprise_value BIGINT,
    
    -- Metadata
    source VARCHAR(50),                        -- 'yfinance', 'screener', 'manual'
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(company_id, period)
);

CREATE INDEX idx_fundamentals_company ON fundamentals(company_id);
CREATE INDEX idx_fundamentals_period ON fundamentals(period);
CREATE INDEX idx_fundamentals_period_end ON fundamentals(period_end_date);
```

#### `prices`

Daily OHLCV data (TimescaleDB hypertable for time-series optimization).

```sql
CREATE TABLE prices (
    id SERIAL,
    company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    open DECIMAL(12, 2),
    high DECIMAL(12, 2),
    low DECIMAL(12, 2),
    close DECIMAL(12, 2),
    adj_close DECIMAL(12, 2),
    volume BIGINT,
    created_at TIMESTAMP DEFAULT NOW(),
    
    PRIMARY KEY (id, date)
);

-- Convert to TimescaleDB hypertable
SELECT create_hypertable('prices', 'date');

CREATE INDEX idx_prices_company_date ON prices(company_id, date DESC);
```

#### `documents`

Metadata for all ingested documents.

```sql
CREATE TYPE document_type AS ENUM (
    'annual_report',
    'quarterly_result',
    'earnings_transcript',
    'investor_presentation',
    'corporate_filing',
    'news_article',
    'other'
);

CREATE TYPE document_status AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed',
    'archived'
);

CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
    doc_type document_type NOT NULL,
    title VARCHAR(500),
    description TEXT,
    
    -- Source
    source_url VARCHAR(1000),
    source_name VARCHAR(100),                  -- 'NSE', 'BSE', 'Company IR'
    
    -- Storage
    storage_path VARCHAR(500),                 -- GCS path
    storage_bucket VARCHAR(100),
    file_size_bytes BIGINT,
    file_type VARCHAR(20),                     -- 'pdf', 'html', 'txt'
    
    -- Content
    content_hash VARCHAR(64) UNIQUE,           -- SHA-256 for deduplication
    page_count INTEGER,
    
    -- Temporal
    fiscal_period VARCHAR(20),                 -- 'FY2024', 'Q3FY24'
    document_date DATE,                        -- Date of the document
    
    -- Processing
    status document_status DEFAULT 'pending',
    chunk_count INTEGER DEFAULT 0,
    vector_ids TEXT[],                         -- Qdrant point IDs
    
    -- Metadata
    raw_metadata JSONB,                        -- Original metadata from source
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_documents_company ON documents(company_id);
CREATE INDEX idx_documents_type ON documents(doc_type);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_fiscal ON documents(fiscal_period);
CREATE INDEX idx_documents_hash ON documents(content_hash);
```

#### `ingestion_logs`

Detailed logs for document processing pipeline.

```sql
CREATE TYPE ingestion_step AS ENUM (
    'download',
    'parse',
    'chunk',
    'embed',
    'index',
    'metadata'
);

CREATE TYPE ingestion_status AS ENUM (
    'started',
    'completed',
    'failed',
    'skipped'
);

CREATE TABLE ingestion_logs (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
    step ingestion_step NOT NULL,
    status ingestion_status NOT NULL,
    
    -- Timing
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    duration_ms INTEGER,
    
    -- Details
    input_data JSONB,
    output_data JSONB,
    error_message TEXT,
    error_traceback TEXT,
    
    -- Metrics
    items_processed INTEGER,
    items_failed INTEGER,
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_ingestion_logs_document ON ingestion_logs(document_id);
CREATE INDEX idx_ingestion_logs_step ON ingestion_logs(step);
CREATE INDEX idx_ingestion_logs_status ON ingestion_logs(status);
```

#### `news_articles`

News articles with sentiment analysis.

```sql
CREATE TABLE news_articles (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
    
    -- Content
    title VARCHAR(500) NOT NULL,
    summary TEXT,
    body TEXT,
    url VARCHAR(1000) UNIQUE,
    
    -- Source
    source VARCHAR(100),                       -- 'Economic Times', 'Moneycontrol'
    author VARCHAR(200),
    
    -- Analysis
    sentiment VARCHAR(20),                     -- 'positive', 'negative', 'neutral'
    sentiment_score DECIMAL(5, 4),             -- -1.0 to 1.0
    topics TEXT[],                             -- ['earnings', 'merger', 'lawsuit']
    entities JSONB,                            -- Extracted named entities
    
    -- Temporal
    published_at TIMESTAMP,
    fetched_at TIMESTAMP DEFAULT NOW(),
    
    -- Processing
    is_indexed BOOLEAN DEFAULT false,
    vector_id VARCHAR(100),
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_news_company ON news_articles(company_id);
CREATE INDEX idx_news_published ON news_articles(published_at DESC);
CREATE INDEX idx_news_source ON news_articles(source);
CREATE INDEX idx_news_sentiment ON news_articles(sentiment);
```

#### `queries`

Query history and responses.

```sql
CREATE TABLE queries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER REFERENCES users(id),
    
    -- Input
    question TEXT NOT NULL,
    filters JSONB,                             -- {company: 'RELIANCE.NS', period: 'FY2024'}
    
    -- Output
    response TEXT,
    citations JSONB,                           -- [{doc_id, chunk_id, text_preview}]
    
    -- Workflow
    workflow_trace_id VARCHAR(100),            -- LangSmith trace ID
    nodes_executed TEXT[],                     -- ['router', 'retrieve', 'generate']
    retry_count INTEGER DEFAULT 0,
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending',      -- 'pending', 'processing', 'completed', 'failed'
    error_message TEXT,
    
    -- Metrics
    latency_ms INTEGER,
    token_count_input INTEGER,
    token_count_output INTEGER,
    cost_usd DECIMAL(10, 6),
    
    -- Quality
    retrieval_score DECIMAL(5, 4),
    faithfulness_score DECIMAL(5, 4),
    relevance_score DECIMAL(5, 4),
    
    -- Feedback
    user_rating INTEGER,                       -- 1-5
    user_feedback TEXT,
    
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

CREATE INDEX idx_queries_user ON queries(user_id);
CREATE INDEX idx_queries_status ON queries(status);
CREATE INDEX idx_queries_created ON queries(created_at DESC);
```

#### `users`

User accounts for authentication.

```sql
CREATE TYPE user_role AS ENUM ('admin', 'user', 'viewer');

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(200),
    role user_role DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    
    -- Limits
    daily_query_limit INTEGER DEFAULT 100,
    queries_today INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
```

#### `hitl_reviews`

Human-in-the-loop review queue.

```sql
CREATE TYPE hitl_status AS ENUM ('pending', 'approved', 'rejected', 'expired');

CREATE TABLE hitl_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_id UUID REFERENCES queries(id),
    
    -- Context
    action_type VARCHAR(50),                   -- 'high_risk_query', 'low_confidence'
    reason TEXT,
    
    -- State
    workflow_state JSONB,                      -- Serialized LangGraph state
    checkpoint_id VARCHAR(100),
    
    -- Review
    status hitl_status DEFAULT 'pending',
    reviewer_id INTEGER REFERENCES users(id),
    reviewer_notes TEXT,
    reviewed_at TIMESTAMP,
    
    -- Timeout
    expires_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_hitl_status ON hitl_reviews(status);
CREATE INDEX idx_hitl_query ON hitl_reviews(query_id);
```

---

## Qdrant Vector Collection Schema

### Collection: `nifty_50_financial_kb`

```python
from qdrant_client.models import (
    VectorParams, Distance, PayloadSchemaType
)

COLLECTION_CONFIG = {
    "collection_name": "nifty_50_financial_kb",
    "vectors_config": {
        # Main content embedding
        "content": VectorParams(
            size=3072,  # text-embedding-3-large
            distance=Distance.COSINE,
            on_disk=True
        ),
        # Summary embedding (for tables/images)
        "summary": VectorParams(
            size=3072,
            distance=Distance.COSINE,
            on_disk=True
        )
    },
    "payload_schema": {
        # Filterable fields
        "company_symbol": PayloadSchemaType.KEYWORD,
        "document_type": PayloadSchemaType.KEYWORD,
        "fiscal_period": PayloadSchemaType.KEYWORD,
        "section": PayloadSchemaType.KEYWORD,
        "chunk_level": PayloadSchemaType.KEYWORD,  # 'fine', 'medium', 'coarse'
        
        # Parent-child relationships
        "parent_id": PayloadSchemaType.KEYWORD,
        "document_id": PayloadSchemaType.INTEGER,
        
        # Content
        "content_type": PayloadSchemaType.KEYWORD,  # 'text', 'table', 'image'
        "content_hash": PayloadSchemaType.KEYWORD,
        
        # Temporal
        "ingestion_timestamp": PayloadSchemaType.DATETIME,
        "document_date": PayloadSchemaType.DATETIME
    }
}
```

### Point Structure

```python
from qdrant_client.models import PointStruct

point = PointStruct(
    id="uuid-string",
    vector={
        "content": [0.1, 0.2, ...],  # 3072 dimensions
        "summary": [0.3, 0.4, ...]   # Optional, for tables
    },
    payload={
        # Identity
        "company_symbol": "RELIANCE.NS",
        "document_id": 123,
        "document_type": "annual_report",
        
        # Hierarchy
        "parent_id": "parent-uuid",
        "chunk_level": "fine",  # 512 tokens
        
        # Content
        "content_type": "text",
        "text": "The actual chunk text content...",
        "text_preview": "First 200 chars...",
        
        # For tables
        "table_markdown": "| Col1 | Col2 |...",
        "table_summary": "This table shows Q3 revenue...",
        
        # Metadata
        "section": "Management Discussion",
        "fiscal_period": "FY2024",
        "page_number": 45,
        
        # Deduplication
        "content_hash": "sha256-hash",
        
        # Timestamps
        "ingestion_timestamp": "2024-11-25T10:30:00Z",
        "document_date": "2024-03-31"
    }
)
```

---

## Pydantic Models (API Schemas)

### Company Models

```python
from pydantic import BaseModel, Field
from datetime import datetime, date
from typing import Optional, List
from enum import Enum

class Sector(str, Enum):
    ENERGY = "Energy"
    BANKING = "Banking"
    IT = "IT"
    PHARMA = "Pharma"
    AUTO = "Auto"
    FMCG = "FMCG"
    METALS = "Metals"
    TELECOM = "Telecom"
    INFRASTRUCTURE = "Infrastructure"
    OTHER = "Other"

class CompanyBase(BaseModel):
    symbol: str = Field(..., example="RELIANCE.NS")
    name: str = Field(..., example="Reliance Industries Ltd")
    sector: Optional[Sector] = None
    industry: Optional[str] = None

class CompanyCreate(CompanyBase):
    market_cap_rank: Optional[int] = Field(None, ge=1, le=50)
    isin: Optional[str] = None
    nse_symbol: Optional[str] = None
    bse_code: Optional[str] = None

class CompanyResponse(CompanyBase):
    id: int
    market_cap_rank: Optional[int]
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class CompanyWithFundamentals(CompanyResponse):
    latest_fundamentals: Optional["FundamentalsResponse"] = None
    latest_price: Optional["PriceResponse"] = None
```

### Fundamentals Models

```python
class FundamentalsBase(BaseModel):
    period: str = Field(..., example="Q3FY24")
    period_type: str = Field(..., pattern="^(quarterly|annual)$")
    
class FundamentalsCreate(FundamentalsBase):
    company_id: int
    revenue: Optional[int] = None
    net_income: Optional[int] = None
    eps: Optional[float] = None
    pe_ratio: Optional[float] = None
    roe: Optional[float] = None
    debt_to_equity: Optional[float] = None
    market_cap: Optional[int] = None

class FundamentalsResponse(FundamentalsBase):
    id: int
    company_id: int
    revenue: Optional[int]
    net_income: Optional[int]
    eps: Optional[float]
    pe_ratio: Optional[float]
    roe: Optional[float]
    debt_to_equity: Optional[float]
    market_cap: Optional[int]
    period_end_date: Optional[date]
    source: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True
```

### Document Models

```python
class DocumentType(str, Enum):
    ANNUAL_REPORT = "annual_report"
    QUARTERLY_RESULT = "quarterly_result"
    EARNINGS_TRANSCRIPT = "earnings_transcript"
    INVESTOR_PRESENTATION = "investor_presentation"
    CORPORATE_FILING = "corporate_filing"
    NEWS_ARTICLE = "news_article"
    OTHER = "other"

class DocumentStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

class DocumentCreate(BaseModel):
    company_id: int
    doc_type: DocumentType
    title: str
    source_url: Optional[str] = None
    fiscal_period: Optional[str] = None
    document_date: Optional[date] = None

class DocumentResponse(BaseModel):
    id: int
    company_id: int
    doc_type: DocumentType
    title: str
    status: DocumentStatus
    chunk_count: int
    storage_path: Optional[str]
    fiscal_period: Optional[str]
    document_date: Optional[date]
    created_at: datetime
    
    class Config:
        from_attributes = True
```

### Query Models

```python
class QueryFilters(BaseModel):
    company_symbol: Optional[str] = None
    fiscal_period: Optional[str] = None
    document_types: Optional[List[DocumentType]] = None
    date_from: Optional[date] = None
    date_to: Optional[date] = None

class QueryRequest(BaseModel):
    question: str = Field(..., min_length=10, max_length=1000)
    filters: Optional[QueryFilters] = None
    stream: bool = False

class Citation(BaseModel):
    document_id: int
    document_title: str
    chunk_id: str
    text_preview: str
    page_number: Optional[int] = None
    relevance_score: float

class QueryResponse(BaseModel):
    id: str
    question: str
    response: str
    citations: List[Citation]
    status: str
    latency_ms: int
    created_at: datetime

class QueryStreamChunk(BaseModel):
    type: str  # 'token', 'citation', 'done', 'error'
    content: str
    metadata: Optional[dict] = None
```

---

## LangGraph State Schema

### Main Agent State

```python
from typing import TypedDict, Annotated, Sequence, Optional, List
from langchain_core.messages import BaseMessage
from langgraph.graph.message import add_messages
from pydantic import BaseModel, Field
from enum import Enum

class QueryType(str, Enum):
    FACTUAL = "factual"           # "What was TCS revenue in FY24?"
    COMPARATIVE = "comparative"    # "Compare HDFC and ICICI PE ratios"
    ANALYTICAL = "analytical"      # "Why did Reliance stock drop?"
    EXPLORATORY = "exploratory"    # "Tell me about Infosys"
    CURRENT_EVENTS = "current"     # "Latest news on Tata Motors"

class RouteDecision(str, Enum):
    VECTOR_STORE = "vector_store"
    WEB_SEARCH = "web_search"
    DIRECT_ANSWER = "direct_answer"
    KNOWLEDGE_GRAPH = "knowledge_graph"  # Phase 2

class QueryAnalysis(BaseModel):
    """Output of query analysis node"""
    query_type: QueryType
    route: RouteDecision
    entities: List[str] = Field(default_factory=list)  # Company names mentioned
    time_references: List[str] = Field(default_factory=list)  # FY24, Q3, etc.
    requires_calculation: bool = False
    sub_questions: List[str] = Field(default_factory=list)

class DocumentGrade(BaseModel):
    """Output of document grading"""
    document_id: str
    is_relevant: bool
    relevance_score: float = Field(ge=0, le=1)
    reasoning: str

class FactCheckResult(BaseModel):
    """Output of fact checking"""
    is_faithful: bool
    unsupported_claims: List[str] = Field(default_factory=list)
    confidence_score: float = Field(ge=0, le=1)
    reasoning: str

class RetrievedDocument(BaseModel):
    """Document retrieved from vector store"""
    id: str
    content: str
    metadata: dict
    score: float
    source: str  # 'vector', 'bm25', 'web'

class AgenticRAGState(TypedDict):
    """Main state for the agentic RAG workflow"""
    
    # Messages (conversation history)
    messages: Annotated[Sequence[BaseMessage], add_messages]
    
    # Query analysis
    original_query: str
    query_analysis: Optional[QueryAnalysis]
    current_query: str  # May be rewritten
    
    # Retrieval
    retrieved_documents: List[RetrievedDocument]
    document_grades: List[DocumentGrade]
    relevant_documents: List[RetrievedDocument]
    
    # Generation
    generated_response: Optional[str]
    fact_check_result: Optional[FactCheckResult]
    
    # Citations
    citations: List[dict]
    
    # Control flow
    route_decision: Optional[RouteDecision]
    rewrite_count: int
    generation_attempt: int
    max_retries: int
    
    # HITL
    requires_human_review: bool
    hitl_reason: Optional[str]
    
    # Metadata
    trace_id: Optional[str]
    user_id: Optional[int]
    filters: Optional[dict]
```

### Node Input/Output Types

```python
class RouterInput(BaseModel):
    query: str
    conversation_history: List[dict] = Field(default_factory=list)

class RouterOutput(BaseModel):
    analysis: QueryAnalysis
    route: RouteDecision

class RetrieverInput(BaseModel):
    query: str
    filters: Optional[dict] = None
    top_k: int = 10

class RetrieverOutput(BaseModel):
    documents: List[RetrievedDocument]
    search_metadata: dict

class GraderInput(BaseModel):
    query: str
    documents: List[RetrievedDocument]

class GraderOutput(BaseModel):
    grades: List[DocumentGrade]
    relevant_documents: List[RetrievedDocument]

class GeneratorInput(BaseModel):
    query: str
    context_documents: List[RetrievedDocument]
    conversation_history: List[dict] = Field(default_factory=list)

class GeneratorOutput(BaseModel):
    response: str
    citations_used: List[str]

class FactCheckerInput(BaseModel):
    response: str
    source_documents: List[RetrievedDocument]

class FactCheckerOutput(BaseModel):
    result: FactCheckResult
    should_regenerate: bool
```

---

## Data Relationships Summary

```
companies (1) ──────────────── (N) fundamentals
    │
    ├──────────────────────── (N) prices
    │
    ├──────────────────────── (N) documents
    │                              │
    │                              └── (N) ingestion_logs
    │
    └──────────────────────── (N) news_articles

users (1) ─────────────────── (N) queries
    │                              │
    │                              └── (1) hitl_reviews
    │
    └──────────────────────── (N) hitl_reviews (as reviewer)

Qdrant Points:
    - Linked to documents via document_id
    - Parent-child relationships via parent_id
    - Filterable by company_symbol, doc_type, fiscal_period
```

---

## Migration Strategy

### Initial Setup

```sql
-- 1. Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Create TimescaleDB extension (for prices)
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- 3. Run migrations in order:
-- migrations/001_create_companies.sql
-- migrations/002_create_fundamentals.sql
-- migrations/003_create_prices.sql
-- migrations/004_create_documents.sql
-- migrations/005_create_users.sql
-- migrations/006_create_queries.sql
-- migrations/007_create_hitl.sql
-- migrations/008_create_news.sql
```

---

## Next Document

Continue to [03-INGESTION-PIPELINE.md](./03-INGESTION-PIPELINE.md) for document collection and processing details.

