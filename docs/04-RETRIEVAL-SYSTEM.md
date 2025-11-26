# 04 - Retrieval System

## Overview

The retrieval system combines multiple search strategies to maximize both recall and precision:

1. **Vector Search** - Semantic similarity using embeddings
2. **BM25 Search** - Keyword-based sparse retrieval
3. **Hybrid Fusion** - Combine results using Reciprocal Rank Fusion
4. **Reranking** - Cross-encoder for precision
5. **Query Enhancement** - HyDE and query expansion

---

## Retrieval Architecture

```
                                    User Query
                                        │
                                        ▼
                              ┌─────────────────┐
                              │ Query Analyzer  │
                              │ (extract filters│
                              │  & intent)      │
                              └────────┬────────┘
                                       │
                         ┌─────────────┴─────────────┐
                         │                           │
                         ▼                           ▼
                  ┌─────────────┐            ┌─────────────┐
                  │   HyDE      │            │   Direct    │
                  │ (optional)  │            │   Query     │
                  └──────┬──────┘            └──────┬──────┘
                         │                          │
                         └──────────┬───────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
             ┌───────────┐  ┌───────────┐  ┌───────────┐
             │  Vector   │  │   BM25    │  │  Filter   │
             │  Search   │  │  Search   │  │  (SQL)    │
             │  (Qdrant) │  │           │  │           │
             └─────┬─────┘  └─────┬─────┘  └─────┬─────┘
                   │              │              │
                   └──────────────┼──────────────┘
                                  │
                                  ▼
                         ┌───────────────┐
                         │  RRF Fusion   │
                         │  (merge &     │
                         │   dedupe)     │
                         └───────┬───────┘
                                 │
                                 ▼
                         ┌───────────────┐
                         │   Reranker    │
                         │ (CrossEncoder)│
                         └───────┬───────┘
                                 │
                                 ▼
                         ┌───────────────┐
                         │ Parent Chunk  │
                         │  Expansion    │
                         └───────┬───────┘
                                 │
                                 ▼
                          Top-K Results
```

---

## Vector Search (Qdrant)

### Basic Vector Search

```python
from qdrant_client import QdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue, Range
from typing import List, Optional, Dict, Any
from dataclasses import dataclass

@dataclass
class SearchResult:
    id: str
    score: float
    content: str
    metadata: Dict[str, Any]
    source: str  # 'vector', 'bm25', 'hybrid'

class VectorSearcher:
    """Semantic search using Qdrant"""
    
    COLLECTION_NAME = "nifty_50_financial_kb"
    
    def __init__(self, client: QdrantClient, embedder):
        self.client = client
        self.embedder = embedder
    
    async def search(
        self,
        query: str,
        top_k: int = 20,
        filters: Optional[Dict] = None,
        vector_name: str = "content"  # or "summary" for table search
    ) -> List[SearchResult]:
        """
        Perform semantic search.
        
        Args:
            query: Natural language query
            top_k: Number of results
            filters: Optional filters (company, doc_type, period)
            vector_name: Which vector to search ("content" or "summary")
        
        Returns:
            List of SearchResult objects
        """
        
        # 1. Embed the query
        query_embedding = await self.embedder.embed_query(query)
        
        # 2. Build Qdrant filter
        qdrant_filter = self._build_filter(filters) if filters else None
        
        # 3. Execute search
        results = self.client.search(
            collection_name=self.COLLECTION_NAME,
            query_vector=(vector_name, query_embedding),
            query_filter=qdrant_filter,
            limit=top_k,
            with_payload=True,
            score_threshold=0.5  # Minimum similarity
        )
        
        # 4. Convert to SearchResult
        return [
            SearchResult(
                id=str(hit.id),
                score=hit.score,
                content=hit.payload.get("text", ""),
                metadata=hit.payload,
                source="vector"
            )
            for hit in results
        ]
    
    def _build_filter(self, filters: Dict) -> Filter:
        """Build Qdrant filter from dict"""
        
        conditions = []
        
        if "company_symbol" in filters:
            conditions.append(
                FieldCondition(
                    key="company_symbol",
                    match=MatchValue(value=filters["company_symbol"])
                )
            )
        
        if "document_type" in filters:
            conditions.append(
                FieldCondition(
                    key="document_type",
                    match=MatchValue(value=filters["document_type"])
                )
            )
        
        if "fiscal_period" in filters:
            conditions.append(
                FieldCondition(
                    key="fiscal_period",
                    match=MatchValue(value=filters["fiscal_period"])
                )
            )
        
        if "document_types" in filters:
            # Multiple document types (OR)
            conditions.append(
                FieldCondition(
                    key="document_type",
                    match=MatchValue(any=filters["document_types"])
                )
            )
        
        return Filter(must=conditions) if conditions else None
```

### Multi-Vector Search

```python
async def multi_vector_search(
    self,
    query: str,
    top_k: int = 20,
    filters: Optional[Dict] = None
) -> List[SearchResult]:
    """
    Search both content and summary vectors.
    
    - Content vectors: For text chunks
    - Summary vectors: For tables (matches against table summaries)
    """
    
    # Search content vectors
    content_results = await self.search(
        query=query,
        top_k=top_k,
        filters=filters,
        vector_name="content"
    )
    
    # Search summary vectors (for tables)
    summary_results = await self.search(
        query=query,
        top_k=top_k // 2,  # Fewer table results
        filters=filters,
        vector_name="summary"
    )
    
    # Merge and deduplicate
    seen_ids = set()
    merged = []
    
    for result in content_results + summary_results:
        if result.id not in seen_ids:
            seen_ids.add(result.id)
            merged.append(result)
    
    # Sort by score
    merged.sort(key=lambda x: x.score, reverse=True)
    
    return merged[:top_k]
```

---

## BM25 Search (Sparse Retrieval)

### Implementation

```python
from rank_bm25 import BM25Okapi
import pickle
from typing import List, Dict
import numpy as np

class BM25Searcher:
    """Keyword-based search using BM25"""
    
    def __init__(self, index_path: str = None):
        self.bm25 = None
        self.documents = []
        self.doc_ids = []
        
        if index_path:
            self.load_index(index_path)
    
    def build_index(self, documents: List[Dict]) -> None:
        """
        Build BM25 index from documents.
        
        Args:
            documents: List of {id, text, metadata} dicts
        """
        
        self.documents = documents
        self.doc_ids = [doc["id"] for doc in documents]
        
        # Tokenize documents
        tokenized = [self._tokenize(doc["text"]) for doc in documents]
        
        # Build BM25 index
        self.bm25 = BM25Okapi(tokenized)
    
    def _tokenize(self, text: str) -> List[str]:
        """Simple tokenization (can be improved with stemming)"""
        import re
        
        # Lowercase and split on non-alphanumeric
        tokens = re.findall(r'\b\w+\b', text.lower())
        
        # Remove stopwords (basic list)
        stopwords = {'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been',
                     'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
                     'would', 'could', 'should', 'may', 'might', 'must', 'shall',
                     'can', 'need', 'dare', 'ought', 'used', 'to', 'of', 'in',
                     'for', 'on', 'with', 'at', 'by', 'from', 'as', 'into',
                     'through', 'during', 'before', 'after', 'above', 'below',
                     'between', 'under', 'again', 'further', 'then', 'once'}
        
        return [t for t in tokens if t not in stopwords and len(t) > 2]
    
    def search(
        self,
        query: str,
        top_k: int = 20,
        filters: Optional[Dict] = None
    ) -> List[SearchResult]:
        """
        Search using BM25.
        
        Args:
            query: Search query
            top_k: Number of results
            filters: Optional metadata filters
        
        Returns:
            List of SearchResult objects
        """
        
        if self.bm25 is None:
            raise ValueError("Index not built. Call build_index first.")
        
        # Tokenize query
        query_tokens = self._tokenize(query)
        
        # Get BM25 scores
        scores = self.bm25.get_scores(query_tokens)
        
        # Apply filters if provided
        if filters:
            for i, doc in enumerate(self.documents):
                if not self._matches_filter(doc, filters):
                    scores[i] = 0
        
        # Get top-k indices
        top_indices = np.argsort(scores)[::-1][:top_k]
        
        # Build results
        results = []
        for idx in top_indices:
            if scores[idx] > 0:
                doc = self.documents[idx]
                results.append(SearchResult(
                    id=doc["id"],
                    score=float(scores[idx]),
                    content=doc["text"],
                    metadata=doc.get("metadata", {}),
                    source="bm25"
                ))
        
        return results
    
    def _matches_filter(self, doc: Dict, filters: Dict) -> bool:
        """Check if document matches filters"""
        metadata = doc.get("metadata", {})
        
        for key, value in filters.items():
            if key in metadata and metadata[key] != value:
                return False
        
        return True
    
    def save_index(self, path: str) -> None:
        """Save index to disk"""
        with open(path, 'wb') as f:
            pickle.dump({
                'bm25': self.bm25,
                'documents': self.documents,
                'doc_ids': self.doc_ids
            }, f)
    
    def load_index(self, path: str) -> None:
        """Load index from disk"""
        with open(path, 'rb') as f:
            data = pickle.load(f)
            self.bm25 = data['bm25']
            self.documents = data['documents']
            self.doc_ids = data['doc_ids']
```

---

## Hybrid Search with RRF

### Reciprocal Rank Fusion

```python
from collections import defaultdict
from typing import List, Dict

class HybridSearcher:
    """Combine vector and BM25 search using RRF"""
    
    def __init__(
        self,
        vector_searcher: VectorSearcher,
        bm25_searcher: BM25Searcher,
        vector_weight: float = 0.6,
        bm25_weight: float = 0.4,
        rrf_k: int = 60  # RRF constant
    ):
        self.vector_searcher = vector_searcher
        self.bm25_searcher = bm25_searcher
        self.vector_weight = vector_weight
        self.bm25_weight = bm25_weight
        self.rrf_k = rrf_k
    
    async def search(
        self,
        query: str,
        top_k: int = 10,
        filters: Optional[Dict] = None
    ) -> List[SearchResult]:
        """
        Hybrid search combining vector and BM25.
        
        Uses Reciprocal Rank Fusion (RRF) to merge results:
        RRF_score = sum(1 / (k + rank_i)) for each retriever
        
        Args:
            query: Search query
            top_k: Final number of results
            filters: Optional metadata filters
        
        Returns:
            Merged and ranked results
        """
        
        # 1. Get results from both retrievers
        vector_results = await self.vector_searcher.search(
            query=query,
            top_k=top_k * 2,  # Get more for fusion
            filters=filters
        )
        
        bm25_results = self.bm25_searcher.search(
            query=query,
            top_k=top_k * 2,
            filters=filters
        )
        
        # 2. Compute RRF scores
        rrf_scores = defaultdict(float)
        doc_map = {}  # id -> SearchResult
        
        # Vector results contribution
        for rank, result in enumerate(vector_results):
            rrf_scores[result.id] += self.vector_weight / (self.rrf_k + rank + 1)
            doc_map[result.id] = result
        
        # BM25 results contribution
        for rank, result in enumerate(bm25_results):
            rrf_scores[result.id] += self.bm25_weight / (self.rrf_k + rank + 1)
            if result.id not in doc_map:
                doc_map[result.id] = result
        
        # 3. Sort by RRF score
        sorted_ids = sorted(rrf_scores.keys(), key=lambda x: rrf_scores[x], reverse=True)
        
        # 4. Build final results
        results = []
        for doc_id in sorted_ids[:top_k]:
            result = doc_map[doc_id]
            result.score = rrf_scores[doc_id]  # Update score to RRF score
            result.source = "hybrid"
            results.append(result)
        
        return results
```

---

## Reranking

### Cross-Encoder Reranker

```python
from sentence_transformers import CrossEncoder
from typing import List

class Reranker:
    """Rerank results using cross-encoder"""
    
    MODEL_NAME = "cross-encoder/ms-marco-MiniLM-L-12-v2"
    
    def __init__(self):
        self.model = CrossEncoder(self.MODEL_NAME)
    
    def rerank(
        self,
        query: str,
        results: List[SearchResult],
        top_k: int = 5
    ) -> List[SearchResult]:
        """
        Rerank results using cross-encoder.
        
        Cross-encoders are more accurate than bi-encoders but slower,
        so we use them on a smaller candidate set.
        
        Args:
            query: Original query
            results: Candidate results from hybrid search
            top_k: Number of results to return
        
        Returns:
            Reranked results
        """
        
        if not results:
            return []
        
        # Prepare pairs for cross-encoder
        pairs = [[query, result.content] for result in results]
        
        # Get cross-encoder scores
        scores = self.model.predict(pairs)
        
        # Attach scores and sort
        for result, score in zip(results, scores):
            result.metadata["rerank_score"] = float(score)
            result.score = float(score)  # Replace with rerank score
        
        # Sort by rerank score
        results.sort(key=lambda x: x.score, reverse=True)
        
        return results[:top_k]
```

### Cohere Reranker (Alternative)

```python
import cohere

class CohereReranker:
    """Rerank using Cohere's rerank API"""
    
    def __init__(self, api_key: str):
        self.client = cohere.Client(api_key)
    
    def rerank(
        self,
        query: str,
        results: List[SearchResult],
        top_k: int = 5
    ) -> List[SearchResult]:
        """Rerank using Cohere"""
        
        if not results:
            return []
        
        # Call Cohere rerank
        response = self.client.rerank(
            model="rerank-english-v2.0",
            query=query,
            documents=[r.content for r in results],
            top_n=top_k
        )
        
        # Map back to results
        reranked = []
        for item in response.results:
            result = results[item.index]
            result.score = item.relevance_score
            result.metadata["rerank_score"] = item.relevance_score
            reranked.append(result)
        
        return reranked
```

---

## Query Enhancement

### HyDE (Hypothetical Document Embeddings)

```python
class HyDEQueryEnhancer:
    """
    Hypothetical Document Embeddings.
    
    Generate a hypothetical answer to the query, then embed that
    instead of the query. This often improves retrieval for
    complex or abstract queries.
    """
    
    HYDE_PROMPT = """You are a financial analyst. Given the following question,
write a short, factual paragraph that would answer it. Write as if you're
quoting from a financial document.

Question: {query}

Hypothetical Answer:"""
    
    def __init__(self, llm, embedder):
        self.llm = llm
        self.embedder = embedder
    
    async def enhance_query(self, query: str) -> str:
        """
        Generate hypothetical document for the query.
        
        Returns:
            Hypothetical answer text (to be embedded)
        """
        
        prompt = self.HYDE_PROMPT.format(query=query)
        
        response = await self.llm.ainvoke(prompt)
        
        return response.content
    
    async def get_enhanced_embedding(self, query: str) -> List[float]:
        """
        Get embedding of hypothetical document.
        
        This embedding is used for vector search instead of
        the raw query embedding.
        """
        
        hypothetical_doc = await self.enhance_query(query)
        embedding = await self.embedder.embed_query(hypothetical_doc)
        
        return embedding
```

### Query Expansion

```python
class QueryExpander:
    """
    Expand query with related terms and variations.
    
    Helps with recall by generating multiple query variants.
    """
    
    EXPANSION_PROMPT = """Given this financial query, generate 3 alternative
phrasings that might retrieve relevant documents. Include:
1. A more specific version
2. A version using different terminology
3. A version expanding abbreviations

Query: {query}

Return only the 3 alternatives, one per line:"""
    
    def __init__(self, llm):
        self.llm = llm
    
    async def expand(self, query: str) -> List[str]:
        """
        Generate query variations.
        
        Returns:
            List of query variants (including original)
        """
        
        prompt = self.EXPANSION_PROMPT.format(query=query)
        response = await self.llm.ainvoke(prompt)
        
        # Parse response
        variants = [line.strip() for line in response.content.split('\n') if line.strip()]
        
        # Include original query
        return [query] + variants[:3]
```

---

## Parent Chunk Expansion

```python
class ParentChunkExpander:
    """
    Expand retrieved child chunks to their parent chunks.
    
    This provides more context to the LLM while still
    retrieving on fine-grained chunks.
    """
    
    def __init__(self, qdrant_client: QdrantClient):
        self.client = qdrant_client
    
    async def expand_to_parents(
        self,
        results: List[SearchResult],
        include_siblings: bool = False
    ) -> List[SearchResult]:
        """
        Expand child chunks to parent chunks.
        
        Args:
            results: Retrieved child chunks
            include_siblings: Whether to include sibling chunks
        
        Returns:
            Results with parent content
        """
        
        expanded = []
        parent_ids_seen = set()
        
        for result in results:
            parent_id = result.metadata.get("parent_id")
            
            if parent_id and parent_id not in parent_ids_seen:
                parent_ids_seen.add(parent_id)
                
                # Fetch parent chunk
                parent = self._fetch_chunk_by_id(parent_id)
                
                if parent:
                    # Create expanded result
                    expanded_result = SearchResult(
                        id=result.id,
                        score=result.score,
                        content=parent["text"],  # Use parent content
                        metadata={
                            **result.metadata,
                            "original_content": result.content,
                            "expanded": True
                        },
                        source=result.source
                    )
                    expanded.append(expanded_result)
                else:
                    expanded.append(result)
            else:
                expanded.append(result)
        
        return expanded
    
    def _fetch_chunk_by_id(self, chunk_id: str) -> Optional[Dict]:
        """Fetch a specific chunk by ID"""
        
        results = self.client.retrieve(
            collection_name="nifty_50_financial_kb",
            ids=[chunk_id],
            with_payload=True
        )
        
        if results:
            return results[0].payload
        return None
```

---

## Complete Retrieval Pipeline

```python
class RetrievalPipeline:
    """
    Complete retrieval pipeline combining all strategies.
    """
    
    def __init__(
        self,
        vector_searcher: VectorSearcher,
        bm25_searcher: BM25Searcher,
        reranker: Reranker,
        hyde_enhancer: Optional[HyDEQueryEnhancer] = None,
        parent_expander: Optional[ParentChunkExpander] = None
    ):
        self.hybrid_searcher = HybridSearcher(vector_searcher, bm25_searcher)
        self.reranker = reranker
        self.hyde_enhancer = hyde_enhancer
        self.parent_expander = parent_expander
    
    async def retrieve(
        self,
        query: str,
        top_k: int = 5,
        filters: Optional[Dict] = None,
        use_hyde: bool = False,
        expand_parents: bool = True
    ) -> List[SearchResult]:
        """
        Full retrieval pipeline.
        
        Steps:
        1. (Optional) HyDE query enhancement
        2. Hybrid search (vector + BM25)
        3. Reranking
        4. (Optional) Parent chunk expansion
        
        Args:
            query: User query
            top_k: Final number of results
            filters: Metadata filters
            use_hyde: Whether to use HyDE
            expand_parents: Whether to expand to parent chunks
        
        Returns:
            Final ranked results
        """
        
        search_query = query
        
        # 1. HyDE enhancement (optional)
        if use_hyde and self.hyde_enhancer:
            search_query = await self.hyde_enhancer.enhance_query(query)
        
        # 2. Hybrid search
        candidates = await self.hybrid_searcher.search(
            query=search_query,
            top_k=top_k * 3,  # Get more for reranking
            filters=filters
        )
        
        # 3. Rerank
        reranked = self.reranker.rerank(
            query=query,  # Use original query for reranking
            results=candidates,
            top_k=top_k
        )
        
        # 4. Parent expansion (optional)
        if expand_parents and self.parent_expander:
            reranked = await self.parent_expander.expand_to_parents(reranked)
        
        return reranked
```

---

## Filter Strategies

### Company-Specific Search

```python
async def search_company(
    pipeline: RetrievalPipeline,
    query: str,
    company_symbol: str,
    top_k: int = 5
) -> List[SearchResult]:
    """Search within a specific company's documents"""
    
    return await pipeline.retrieve(
        query=query,
        top_k=top_k,
        filters={"company_symbol": company_symbol}
    )
```

### Time-Bounded Search

```python
async def search_period(
    pipeline: RetrievalPipeline,
    query: str,
    fiscal_period: str,  # e.g., "FY2024", "Q3FY24"
    top_k: int = 5
) -> List[SearchResult]:
    """Search within a specific fiscal period"""
    
    return await pipeline.retrieve(
        query=query,
        top_k=top_k,
        filters={"fiscal_period": fiscal_period}
    )
```

### Document Type Search

```python
async def search_by_doc_type(
    pipeline: RetrievalPipeline,
    query: str,
    doc_types: List[str],  # e.g., ["annual_report", "quarterly_result"]
    top_k: int = 5
) -> List[SearchResult]:
    """Search within specific document types"""
    
    return await pipeline.retrieve(
        query=query,
        top_k=top_k,
        filters={"document_types": doc_types}
    )
```

---

## Performance Optimization

### Caching

```python
import redis
import json
import hashlib
from typing import Optional

class RetrievalCache:
    """Cache retrieval results in Redis"""
    
    def __init__(self, redis_client: redis.Redis, ttl: int = 3600):
        self.redis = redis_client
        self.ttl = ttl
    
    def _cache_key(self, query: str, filters: Optional[Dict]) -> str:
        """Generate cache key"""
        data = {"query": query, "filters": filters or {}}
        return f"retrieval:{hashlib.md5(json.dumps(data, sort_keys=True).encode()).hexdigest()}"
    
    async def get(self, query: str, filters: Optional[Dict]) -> Optional[List[SearchResult]]:
        """Get cached results"""
        key = self._cache_key(query, filters)
        data = self.redis.get(key)
        
        if data:
            results_data = json.loads(data)
            return [SearchResult(**r) for r in results_data]
        
        return None
    
    async def set(self, query: str, filters: Optional[Dict], results: List[SearchResult]) -> None:
        """Cache results"""
        key = self._cache_key(query, filters)
        data = json.dumps([r.__dict__ for r in results])
        self.redis.setex(key, self.ttl, data)
```

### Batch Retrieval

```python
async def batch_retrieve(
    pipeline: RetrievalPipeline,
    queries: List[str],
    top_k: int = 5
) -> Dict[str, List[SearchResult]]:
    """Retrieve for multiple queries in parallel"""
    
    import asyncio
    
    tasks = [
        pipeline.retrieve(query=q, top_k=top_k)
        for q in queries
    ]
    
    results = await asyncio.gather(*tasks)
    
    return dict(zip(queries, results))
```

---

## Metrics and Monitoring

```python
from prometheus_client import Histogram, Counter

# Latency metrics
retrieval_latency = Histogram(
    'retrieval_latency_seconds',
    'Retrieval latency',
    ['method'],  # 'vector', 'bm25', 'hybrid', 'rerank'
    buckets=[0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
)

# Result metrics
retrieval_results = Histogram(
    'retrieval_results_count',
    'Number of results returned',
    buckets=[0, 1, 5, 10, 20, 50]
)

# Cache metrics
cache_hits = Counter(
    'retrieval_cache_hits_total',
    'Cache hits'
)

cache_misses = Counter(
    'retrieval_cache_misses_total',
    'Cache misses'
)
```

---

## Next Document

Continue to [05-AGENTIC-WORKFLOW.md](./05-AGENTIC-WORKFLOW.md) for LangGraph workflow implementation.

