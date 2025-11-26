# 03 - Ingestion Pipeline

## Overview

The ingestion pipeline is responsible for:
1. **Collecting** documents from various sources
2. **Parsing** PDFs and extracting structured content
3. **Chunking** documents with multiple strategies
4. **Embedding** chunks for vector search
5. **Indexing** in Qdrant and PostgreSQL

---

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INGESTION PIPELINE                                 │
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │  COLLECT    │───►│   PARSE     │───►│   CHUNK     │───►│   EMBED     │  │
│  │             │    │             │    │             │    │             │  │
│  │ - NSE/BSE   │    │ - LlamaParse│    │ - Hierarchi-│    │ - OpenAI    │  │
│  │ - Company IR│    │ - Tables    │    │   cal       │    │ - Batch     │  │
│  │ - RSS Feeds │    │ - Sections  │    │ - Semantic  │    │ - Cache     │  │
│  │ - yfinance  │    │ - Metadata  │    │ - Parent-   │    │             │  │
│  │             │    │             │    │   Child     │    │             │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│         │                  │                  │                  │          │
│         ▼                  ▼                  ▼                  ▼          │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │ GCS Storage │    │ PostgreSQL  │    │ PostgreSQL  │    │   Qdrant    │  │
│  │ (raw files) │    │ (metadata)  │    │ (chunks)    │    │ (vectors)   │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Sources

### 1. Annual Reports

| Aspect | Details |
|--------|---------|
| **Sources** | NSE, BSE, Company IR pages |
| **Format** | PDF (50-500 pages) |
| **Frequency** | Annual (April-May each year) |
| **Volume** | 50 companies × 3 years = 150 documents |
| **Size** | 5-50 MB per document |

**Collection Strategy**:
```python
# Primary: NSE Corporate Filings
NSE_ANNUAL_REPORTS_URL = "https://www.nseindia.com/companies-listing/corporate-filings-annual-reports"

# Fallback: Company IR pages
COMPANY_IR_PAGES = {
    "RELIANCE.NS": "https://www.ril.com/investors/annual-reports",
    "HDFCBANK.NS": "https://www.hdfcbank.com/investor-relations/annual-reports",
    "TCS.NS": "https://www.tcs.com/investor-relations/annual-reports",
    # ... 47 more
}
```

### 2. Quarterly Results

| Aspect | Details |
|--------|---------|
| **Sources** | NSE, BSE announcements |
| **Format** | PDF (2-20 pages) |
| **Frequency** | Quarterly (Jan, Apr, Jul, Oct) |
| **Volume** | 50 companies × 8 quarters = 400 documents |
| **Size** | 0.5-5 MB per document |

**Collection Strategy**:
```python
# NSE Announcements API
NSE_ANNOUNCEMENTS_URL = "https://www.nseindia.com/api/corporate-announcements"

# Parameters
params = {
    "index": "equities",
    "symbol": "RELIANCE",
    "issuer": "",
    "subject": "Financial Results",
    "from_date": "01-01-2023",
    "to_date": "25-11-2024"
}
```

### 3. News Articles

| Aspect | Details |
|--------|---------|
| **Sources** | Economic Times, Moneycontrol, Reuters |
| **Format** | RSS/XML → JSON |
| **Frequency** | Real-time (poll every 5 min) |
| **Volume** | ~100-500 articles/day for all NIFTY 50 |
| **Retention** | Rolling 30 days |

**RSS Feeds**:
```python
NEWS_RSS_FEEDS = [
    {
        "name": "Economic Times Markets",
        "url": "https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms",
        "category": "markets"
    },
    {
        "name": "Moneycontrol Markets",
        "url": "https://www.moneycontrol.com/rss/marketreports.xml",
        "category": "markets"
    },
    {
        "name": "Economic Times Companies",
        "url": "https://economictimes.indiatimes.com/news/company/rssfeeds/2143429.cms",
        "category": "companies"
    }
]
```

### 4. Price Data

| Aspect | Details |
|--------|---------|
| **Source** | yfinance |
| **Format** | OHLCV DataFrame |
| **Frequency** | Daily EOD (6 PM IST) |
| **Volume** | 50 companies × 750 trading days (3 years) |

**Collection**:
```python
import yfinance as yf

def fetch_price_data(symbol: str, period: str = "3y") -> pd.DataFrame:
    """Fetch OHLCV data from yfinance"""
    ticker = yf.Ticker(symbol)
    df = ticker.history(period=period)
    return df[['Open', 'High', 'Low', 'Close', 'Volume']]
```

### 5. Fundamentals

| Aspect | Details |
|--------|---------|
| **Sources** | yfinance, Screener.in |
| **Format** | Structured JSON |
| **Frequency** | Quarterly update |
| **Metrics** | Revenue, Net Income, EPS, PE, ROE, etc. |

**Collection**:
```python
def fetch_fundamentals(symbol: str) -> dict:
    """Fetch fundamental data from yfinance"""
    ticker = yf.Ticker(symbol)
    
    return {
        "market_cap": ticker.info.get("marketCap"),
        "pe_ratio": ticker.info.get("trailingPE"),
        "pb_ratio": ticker.info.get("priceToBook"),
        "roe": ticker.info.get("returnOnEquity"),
        "debt_to_equity": ticker.info.get("debtToEquity"),
        "revenue": ticker.info.get("totalRevenue"),
        "net_income": ticker.info.get("netIncome"),
        "eps": ticker.info.get("trailingEps"),
        "dividend_yield": ticker.info.get("dividendYield"),
        "book_value": ticker.info.get("bookValue")
    }
```

---

## Document Parsing

### LlamaParse Configuration

```python
from llama_parse import LlamaParse

LLAMAPARSE_CONFIG = {
    # Output format
    "result_type": "markdown",
    
    # Table handling (critical for financial docs)
    "output_tables_as_HTML": True,  # Better for complex tables
    "spreadsheet_extract_sub_tables": True,  # Separate multiple tables
    
    # Structure preservation
    "preserve_layout": True,
    "extract_images": False,  # Skip images for now
    
    # Performance
    "num_workers": 4,
    "verbose": True
}

parser = LlamaParse(
    api_key=os.environ["LLAMA_CLOUD_API_KEY"],
    **LLAMAPARSE_CONFIG
)
```

### Parsing Pipeline

```python
from dataclasses import dataclass
from typing import List, Optional
import hashlib

@dataclass
class ParsedDocument:
    """Output of document parsing"""
    content: str                    # Full markdown content
    tables: List[dict]              # Extracted tables
    sections: List[dict]            # Section hierarchy
    metadata: dict                  # Document metadata
    content_hash: str               # SHA-256 for deduplication

class DocumentParser:
    """Parse documents using LlamaParse"""
    
    def __init__(self, parser: LlamaParse):
        self.parser = parser
    
    async def parse(self, file_path: str, doc_type: str) -> ParsedDocument:
        """Parse a document and extract structured content"""
        
        # 1. Parse with LlamaParse
        documents = await self.parser.aload_data(file_path)
        
        # 2. Extract full content
        content = "\n\n".join([doc.text for doc in documents])
        
        # 3. Extract tables (HTML format)
        tables = self._extract_tables(content)
        
        # 4. Extract section hierarchy
        sections = self._extract_sections(content)
        
        # 5. Build metadata
        metadata = self._build_metadata(documents, doc_type)
        
        # 6. Compute content hash
        content_hash = hashlib.sha256(content.encode()).hexdigest()
        
        return ParsedDocument(
            content=content,
            tables=tables,
            sections=sections,
            metadata=metadata,
            content_hash=content_hash
        )
    
    def _extract_tables(self, content: str) -> List[dict]:
        """Extract HTML tables from parsed content"""
        import re
        from bs4 import BeautifulSoup
        
        tables = []
        # Find HTML tables
        table_pattern = r'<table.*?</table>'
        matches = re.findall(table_pattern, content, re.DOTALL)
        
        for i, table_html in enumerate(matches):
            soup = BeautifulSoup(table_html, 'html.parser')
            
            # Extract headers
            headers = [th.get_text(strip=True) for th in soup.find_all('th')]
            
            # Extract rows
            rows = []
            for tr in soup.find_all('tr')[1:]:  # Skip header row
                cells = [td.get_text(strip=True) for td in tr.find_all('td')]
                if cells:
                    rows.append(cells)
            
            tables.append({
                "index": i,
                "html": table_html,
                "headers": headers,
                "rows": rows,
                "row_count": len(rows)
            })
        
        return tables
    
    def _extract_sections(self, content: str) -> List[dict]:
        """Extract section hierarchy from markdown headers"""
        import re
        
        sections = []
        # Match markdown headers
        header_pattern = r'^(#{1,6})\s+(.+)$'
        
        lines = content.split('\n')
        current_position = 0
        
        for line in lines:
            match = re.match(header_pattern, line)
            if match:
                level = len(match.group(1))
                title = match.group(2).strip()
                sections.append({
                    "level": level,
                    "title": title,
                    "position": current_position
                })
            current_position += len(line) + 1
        
        return sections
    
    def _build_metadata(self, documents: List, doc_type: str) -> dict:
        """Build metadata from parsed documents"""
        return {
            "page_count": len(documents),
            "doc_type": doc_type,
            "parse_timestamp": datetime.utcnow().isoformat()
        }
```

---

## Chunking Strategies

### Strategy Overview

| Strategy | Chunk Size | Use Case | Pros | Cons |
|----------|-----------|----------|------|------|
| **Hierarchical** | 512, 1024, 2048 | General documents | Multi-granularity | More storage |
| **Semantic** | Variable | Complex narratives | Topic-aware | Slower |
| **Section-based** | By section | Structured docs | Preserves context | Variable sizes |
| **Table-aware** | Per table | Financial tables | Keeps tables intact | Large chunks |

### Implementation

```python
from llama_index.core.node_parser import (
    HierarchicalNodeParser,
    SentenceSplitter,
    get_leaf_nodes
)
from llama_index.core.schema import Document, TextNode
from typing import List, Tuple

class MultiStrategyChunker:
    """Chunk documents using multiple strategies"""
    
    def __init__(self):
        # Hierarchical chunker (multiple granularities)
        self.hierarchical_parser = HierarchicalNodeParser.from_defaults(
            chunk_sizes=[2048, 1024, 512],
            chunk_overlap=50
        )
        
        # Sentence splitter for fine-grained chunks
        self.sentence_splitter = SentenceSplitter(
            chunk_size=512,
            chunk_overlap=50
        )
    
    def chunk_document(
        self,
        parsed_doc: ParsedDocument,
        company_symbol: str,
        doc_type: str,
        fiscal_period: str
    ) -> Tuple[List[TextNode], List[TextNode]]:
        """
        Chunk a document and return:
        - parent_chunks: Larger chunks for context expansion
        - child_chunks: Smaller chunks for retrieval
        """
        
        # Create LlamaIndex document
        document = Document(
            text=parsed_doc.content,
            metadata={
                "company_symbol": company_symbol,
                "document_type": doc_type,
                "fiscal_period": fiscal_period,
                "content_hash": parsed_doc.content_hash
            }
        )
        
        # 1. Hierarchical chunking for text
        all_nodes = self.hierarchical_parser.get_nodes_from_documents([document])
        
        # Separate parent and child nodes
        parent_chunks = [n for n in all_nodes if n.metadata.get("chunk_level") == "coarse"]
        child_chunks = get_leaf_nodes(all_nodes)
        
        # 2. Handle tables separately
        table_chunks = self._chunk_tables(parsed_doc.tables, company_symbol, doc_type)
        
        # Add table chunks to children
        child_chunks.extend(table_chunks)
        
        # 3. Add section metadata to all chunks
        self._add_section_metadata(child_chunks, parsed_doc.sections)
        
        return parent_chunks, child_chunks
    
    def _chunk_tables(
        self,
        tables: List[dict],
        company_symbol: str,
        doc_type: str
    ) -> List[TextNode]:
        """Create chunks for each table with summary"""
        
        table_chunks = []
        
        for table in tables:
            # Generate table summary using LLM (async in practice)
            summary = self._generate_table_summary(table)
            
            chunk = TextNode(
                text=table["html"],  # Store full HTML
                metadata={
                    "company_symbol": company_symbol,
                    "document_type": doc_type,
                    "content_type": "table",
                    "table_index": table["index"],
                    "table_summary": summary,
                    "row_count": table["row_count"],
                    "headers": table["headers"]
                }
            )
            table_chunks.append(chunk)
        
        return table_chunks
    
    def _generate_table_summary(self, table: dict) -> str:
        """Generate natural language summary of table for embedding"""
        # In practice, call LLM here
        headers = ", ".join(table["headers"][:5])
        return f"Table with columns: {headers}. Contains {table['row_count']} rows of data."
    
    def _add_section_metadata(
        self,
        chunks: List[TextNode],
        sections: List[dict]
    ) -> None:
        """Add section context to each chunk"""
        
        for chunk in chunks:
            # Find the section this chunk belongs to
            chunk_start = chunk.start_char_idx or 0
            
            current_section = None
            for section in sections:
                if section["position"] <= chunk_start:
                    current_section = section["title"]
                else:
                    break
            
            if current_section:
                chunk.metadata["section"] = current_section
```

### Parent-Child Relationship

```python
from uuid import uuid4

def create_parent_child_links(
    parent_chunks: List[TextNode],
    child_chunks: List[TextNode]
) -> Tuple[List[TextNode], List[TextNode]]:
    """
    Link child chunks to their parent chunks.
    
    This enables:
    1. Retrieve on child (fine-grained)
    2. Expand to parent for more context
    """
    
    # Assign IDs to parents
    for parent in parent_chunks:
        parent.id_ = str(uuid4())
    
    # Link children to parents based on character positions
    for child in child_chunks:
        child_start = child.start_char_idx or 0
        child_end = child.end_char_idx or len(child.text)
        
        # Find containing parent
        for parent in parent_chunks:
            parent_start = parent.start_char_idx or 0
            parent_end = parent.end_char_idx or len(parent.text)
            
            if parent_start <= child_start and child_end <= parent_end:
                child.metadata["parent_id"] = parent.id_
                break
        
        # Assign child ID
        child.id_ = str(uuid4())
    
    return parent_chunks, child_chunks
```

---

## Embedding Pipeline

### Configuration

```python
from openai import OpenAI
from typing import List
import numpy as np

EMBEDDING_CONFIG = {
    "model": "text-embedding-3-large",
    "dimensions": 3072,
    "batch_size": 100,  # OpenAI limit is 2048
    "max_tokens_per_text": 8191
}

class EmbeddingPipeline:
    """Generate embeddings for document chunks"""
    
    def __init__(self):
        self.client = OpenAI()
        self.cache = {}  # In-memory cache (use Redis in production)
    
    async def embed_chunks(
        self,
        chunks: List[TextNode],
        embed_type: str = "content"  # 'content' or 'summary'
    ) -> List[Tuple[str, List[float]]]:
        """
        Embed chunks and return (chunk_id, embedding) pairs.
        
        For tables:
        - embed_type='content' embeds the full table
        - embed_type='summary' embeds the table summary
        """
        
        results = []
        texts_to_embed = []
        chunk_ids = []
        
        for chunk in chunks:
            chunk_id = chunk.id_
            
            # Get text to embed
            if embed_type == "summary" and chunk.metadata.get("content_type") == "table":
                text = chunk.metadata.get("table_summary", chunk.text)
            else:
                text = chunk.text
            
            # Check cache
            cache_key = f"{embed_type}:{hash(text)}"
            if cache_key in self.cache:
                results.append((chunk_id, self.cache[cache_key]))
                continue
            
            texts_to_embed.append(text)
            chunk_ids.append(chunk_id)
        
        # Batch embed
        if texts_to_embed:
            embeddings = await self._batch_embed(texts_to_embed)
            
            for chunk_id, text, embedding in zip(chunk_ids, texts_to_embed, embeddings):
                cache_key = f"{embed_type}:{hash(text)}"
                self.cache[cache_key] = embedding
                results.append((chunk_id, embedding))
        
        return results
    
    async def _batch_embed(self, texts: List[str]) -> List[List[float]]:
        """Embed texts in batches"""
        
        all_embeddings = []
        batch_size = EMBEDDING_CONFIG["batch_size"]
        
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            
            # Truncate long texts
            batch = [t[:EMBEDDING_CONFIG["max_tokens_per_text"] * 4] for t in batch]
            
            response = self.client.embeddings.create(
                model=EMBEDDING_CONFIG["model"],
                input=batch,
                dimensions=EMBEDDING_CONFIG["dimensions"]
            )
            
            embeddings = [item.embedding for item in response.data]
            all_embeddings.extend(embeddings)
        
        return all_embeddings
```

---

## Indexing

### Qdrant Indexing

```python
from qdrant_client import QdrantClient
from qdrant_client.models import (
    PointStruct,
    VectorParams,
    Distance,
    UpdateStatus
)
from typing import List, Dict
import uuid

class QdrantIndexer:
    """Index chunks in Qdrant vector database"""
    
    COLLECTION_NAME = "nifty_50_financial_kb"
    
    def __init__(self, host: str = "localhost", port: int = 6333):
        self.client = QdrantClient(host=host, port=port)
        self._ensure_collection()
    
    def _ensure_collection(self):
        """Create collection if it doesn't exist"""
        
        collections = self.client.get_collections().collections
        exists = any(c.name == self.COLLECTION_NAME for c in collections)
        
        if not exists:
            self.client.create_collection(
                collection_name=self.COLLECTION_NAME,
                vectors_config={
                    "content": VectorParams(
                        size=3072,
                        distance=Distance.COSINE,
                        on_disk=True
                    ),
                    "summary": VectorParams(
                        size=3072,
                        distance=Distance.COSINE,
                        on_disk=True
                    )
                }
            )
    
    async def index_chunks(
        self,
        chunks: List[TextNode],
        content_embeddings: List[Tuple[str, List[float]]],
        summary_embeddings: List[Tuple[str, List[float]]],
        document_id: int
    ) -> List[str]:
        """
        Index chunks with their embeddings.
        
        Returns list of point IDs for tracking.
        """
        
        # Build embedding lookup
        content_lookup = {cid: emb for cid, emb in content_embeddings}
        summary_lookup = {cid: emb for cid, emb in summary_embeddings}
        
        points = []
        point_ids = []
        
        for chunk in chunks:
            chunk_id = chunk.id_
            point_id = str(uuid.uuid4())
            point_ids.append(point_id)
            
            # Build vectors dict
            vectors = {}
            if chunk_id in content_lookup:
                vectors["content"] = content_lookup[chunk_id]
            if chunk_id in summary_lookup:
                vectors["summary"] = summary_lookup[chunk_id]
            
            # Build payload
            payload = {
                "chunk_id": chunk_id,
                "document_id": document_id,
                "text": chunk.text,
                "text_preview": chunk.text[:200],
                **chunk.metadata
            }
            
            points.append(PointStruct(
                id=point_id,
                vector=vectors,
                payload=payload
            ))
        
        # Batch upsert
        batch_size = 100
        for i in range(0, len(points), batch_size):
            batch = points[i:i + batch_size]
            self.client.upsert(
                collection_name=self.COLLECTION_NAME,
                points=batch
            )
        
        return point_ids
    
    async def delete_document_chunks(self, document_id: int) -> int:
        """Delete all chunks for a document (for re-indexing)"""
        
        result = self.client.delete(
            collection_name=self.COLLECTION_NAME,
            points_selector={
                "filter": {
                    "must": [
                        {"key": "document_id", "match": {"value": document_id}}
                    ]
                }
            }
        )
        
        return result.status == UpdateStatus.COMPLETED
```

---

## Celery Tasks

### Task Definitions

```python
from celery import Celery
from celery.schedules import crontab

app = Celery('ingestion')
app.config_from_object('celeryconfig')

# Scheduled tasks
app.conf.beat_schedule = {
    'collect-news-every-5-minutes': {
        'task': 'tasks.collect_news',
        'schedule': crontab(minute='*/5'),
    },
    'collect-prices-daily': {
        'task': 'tasks.collect_prices',
        'schedule': crontab(hour=18, minute=30),  # 6:30 PM IST
    },
    'check-new-filings-every-30-minutes': {
        'task': 'tasks.check_new_filings',
        'schedule': crontab(minute='*/30'),
    },
    'collect-fundamentals-weekly': {
        'task': 'tasks.collect_fundamentals',
        'schedule': crontab(day_of_week='sunday', hour=0),
    },
}

@app.task(bind=True, max_retries=3)
def ingest_document(self, document_id: int):
    """
    Full ingestion pipeline for a single document.
    
    Steps:
    1. Download from source
    2. Parse with LlamaParse
    3. Chunk with multi-strategy
    4. Embed chunks
    5. Index in Qdrant
    6. Update PostgreSQL metadata
    """
    try:
        # Implementation here
        pass
    except Exception as exc:
        self.retry(exc=exc, countdown=60 * (self.request.retries + 1))

@app.task
def collect_news():
    """Collect news from RSS feeds"""
    pass

@app.task
def collect_prices():
    """Collect EOD prices for all NIFTY 50"""
    pass

@app.task
def check_new_filings():
    """Check NSE/BSE for new corporate filings"""
    pass

@app.task
def collect_fundamentals():
    """Update fundamental data for all companies"""
    pass

@app.task
def bootstrap_all():
    """
    One-time task to ingest all historical documents.
    
    - 150 annual reports (3 years × 50 companies)
    - 400 quarterly results (8 quarters × 50 companies)
    - 3 years of price data
    - Current fundamentals
    """
    pass
```

---

## Deduplication Strategy

```python
import hashlib
from typing import Optional

class DeduplicationService:
    """Prevent duplicate document ingestion"""
    
    def __init__(self, db_session):
        self.db = db_session
    
    def compute_hash(self, content: bytes) -> str:
        """Compute SHA-256 hash of content"""
        return hashlib.sha256(content).hexdigest()
    
    async def is_duplicate(self, content_hash: str) -> bool:
        """Check if document already exists"""
        result = await self.db.execute(
            "SELECT id FROM documents WHERE content_hash = $1",
            content_hash
        )
        return result is not None
    
    async def find_similar_document(
        self,
        company_id: int,
        doc_type: str,
        fiscal_period: str
    ) -> Optional[int]:
        """Find existing document for same company/period"""
        result = await self.db.execute(
            """
            SELECT id FROM documents 
            WHERE company_id = $1 
            AND doc_type = $2 
            AND fiscal_period = $3
            AND status = 'completed'
            """,
            company_id, doc_type, fiscal_period
        )
        return result
```

---

## Error Handling

```python
from enum import Enum
from dataclasses import dataclass
from typing import Optional

class IngestionError(Enum):
    DOWNLOAD_FAILED = "download_failed"
    PARSE_FAILED = "parse_failed"
    CHUNK_FAILED = "chunk_failed"
    EMBED_FAILED = "embed_failed"
    INDEX_FAILED = "index_failed"
    DUPLICATE = "duplicate"

@dataclass
class IngestionResult:
    success: bool
    document_id: int
    error: Optional[IngestionError] = None
    error_message: Optional[str] = None
    chunks_created: int = 0
    vectors_indexed: int = 0

async def handle_ingestion_error(
    document_id: int,
    step: str,
    error: Exception
) -> None:
    """Log error and update document status"""
    
    # Log to ingestion_logs table
    await db.execute(
        """
        INSERT INTO ingestion_logs (document_id, step, status, error_message, error_traceback)
        VALUES ($1, $2, 'failed', $3, $4)
        """,
        document_id, step, str(error), traceback.format_exc()
    )
    
    # Update document status
    await db.execute(
        "UPDATE documents SET status = 'failed' WHERE id = $1",
        document_id
    )
    
    # Alert if critical
    if step in ['parse', 'embed']:
        await send_alert(f"Ingestion failed for document {document_id}: {error}")
```

---

## Monitoring Metrics

```python
from prometheus_client import Counter, Histogram, Gauge

# Counters
documents_ingested = Counter(
    'ingestion_documents_total',
    'Total documents ingested',
    ['doc_type', 'status']
)

chunks_created = Counter(
    'ingestion_chunks_total',
    'Total chunks created',
    ['doc_type']
)

# Histograms
ingestion_duration = Histogram(
    'ingestion_duration_seconds',
    'Time to ingest a document',
    ['doc_type', 'step']
)

embedding_duration = Histogram(
    'embedding_duration_seconds',
    'Time to embed chunks',
    ['batch_size']
)

# Gauges
pending_documents = Gauge(
    'ingestion_pending_documents',
    'Documents waiting to be processed'
)

index_size = Gauge(
    'qdrant_index_size_points',
    'Number of points in Qdrant index'
)
```

---

## Next Document

Continue to [04-RETRIEVAL-SYSTEM.md](./04-RETRIEVAL-SYSTEM.md) for hybrid search and retrieval strategies.

