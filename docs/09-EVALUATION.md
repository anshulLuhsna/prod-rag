# 09 - Evaluation & Monitoring

## Overview

This document covers:
- RAG evaluation metrics (RAGAS)
- Agent trajectory evaluation
- Observability with LangSmith
- Production monitoring
- Alerting and incident response

---

## RAG Evaluation Metrics

### RAGAS Framework

RAGAS (Retrieval Augmented Generation Assessment) provides standardized metrics for evaluating RAG systems.

```
┌─────────────────────────────────────────────────────────────────┐
│                    RAGAS Evaluation Pipeline                     │
│                                                                  │
│  Input: {question, ground_truth, contexts, answer}              │
│                                                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Context Metrics │  │ Answer Metrics  │  │ E2E Metrics     │ │
│  │                 │  │                 │  │                 │ │
│  │ - Precision     │  │ - Faithfulness  │  │ - Answer        │ │
│  │ - Recall        │  │ - Relevancy     │  │   Correctness   │ │
│  │ - Relevancy     │  │ - Semantic      │  │ - Answer        │ │
│  │                 │  │   Similarity    │  │   Similarity    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                  │
│  Output: Scores (0-1) for each metric                           │
└─────────────────────────────────────────────────────────────────┘
```

### Metric Definitions

| Metric | Formula | What it Measures | Target |
|--------|---------|------------------|--------|
| **Context Precision** | Relevant contexts / Total contexts | Are retrieved docs useful? | >0.85 |
| **Context Recall** | Relevant retrieved / Total relevant | Did we find all relevant docs? | >0.90 |
| **Faithfulness** | Supported claims / Total claims | Is answer grounded in context? | >0.95 |
| **Answer Relevancy** | Semantic similarity(answer, question) | Does answer address question? | >0.85 |
| **Answer Correctness** | F1(answer, ground_truth) | Is answer factually correct? | >0.80 |

### Implementation

```python
# evaluation/ragas_eval.py

from ragas import evaluate
from ragas.metrics import (
    context_precision,
    context_recall,
    faithfulness,
    answer_relevancy,
    answer_correctness,
    answer_similarity
)
from datasets import Dataset
from typing import List, Dict
import json

class RAGASEvaluator:
    """Evaluate RAG system using RAGAS metrics"""
    
    def __init__(self, llm=None, embeddings=None):
        self.metrics = [
            context_precision,
            context_recall,
            faithfulness,
            answer_relevancy,
            answer_correctness,
        ]
        
        # Configure LLM for evaluation (can use different from production)
        if llm:
            for metric in self.metrics:
                metric.llm = llm
        
        if embeddings:
            for metric in self.metrics:
                if hasattr(metric, 'embeddings'):
                    metric.embeddings = embeddings
    
    def evaluate_single(
        self,
        question: str,
        answer: str,
        contexts: List[str],
        ground_truth: str
    ) -> Dict[str, float]:
        """Evaluate a single query-answer pair"""
        
        dataset = Dataset.from_dict({
            "question": [question],
            "answer": [answer],
            "contexts": [contexts],
            "ground_truth": [ground_truth]
        })
        
        results = evaluate(dataset, metrics=self.metrics)
        
        return {
            "context_precision": results["context_precision"],
            "context_recall": results["context_recall"],
            "faithfulness": results["faithfulness"],
            "answer_relevancy": results["answer_relevancy"],
            "answer_correctness": results["answer_correctness"]
        }
    
    def evaluate_batch(
        self,
        eval_data: List[Dict]
    ) -> Dict[str, float]:
        """
        Evaluate a batch of query-answer pairs.
        
        Args:
            eval_data: List of {question, answer, contexts, ground_truth}
        
        Returns:
            Average scores for each metric
        """
        
        dataset = Dataset.from_dict({
            "question": [d["question"] for d in eval_data],
            "answer": [d["answer"] for d in eval_data],
            "contexts": [d["contexts"] for d in eval_data],
            "ground_truth": [d["ground_truth"] for d in eval_data]
        })
        
        results = evaluate(dataset, metrics=self.metrics)
        
        return results
    
    def create_eval_report(
        self,
        results: Dict[str, float],
        output_path: str = None
    ) -> str:
        """Generate evaluation report"""
        
        report = f"""
# RAG Evaluation Report
Generated: {datetime.utcnow().isoformat()}

## Summary Scores

| Metric | Score | Target | Status |
|--------|-------|--------|--------|
| Context Precision | {results['context_precision']:.3f} | >0.85 | {'✅' if results['context_precision'] > 0.85 else '❌'} |
| Context Recall | {results['context_recall']:.3f} | >0.90 | {'✅' if results['context_recall'] > 0.90 else '❌'} |
| Faithfulness | {results['faithfulness']:.3f} | >0.95 | {'✅' if results['faithfulness'] > 0.95 else '❌'} |
| Answer Relevancy | {results['answer_relevancy']:.3f} | >0.85 | {'✅' if results['answer_relevancy'] > 0.85 else '❌'} |
| Answer Correctness | {results['answer_correctness']:.3f} | >0.80 | {'✅' if results['answer_correctness'] > 0.80 else '❌'} |

## Interpretation

- **Context Precision**: {'Good' if results['context_precision'] > 0.85 else 'Needs improvement'} - Retrieved documents are {'mostly' if results['context_precision'] > 0.85 else 'not sufficiently'} relevant.
- **Context Recall**: {'Good' if results['context_recall'] > 0.90 else 'Needs improvement'} - {'Most' if results['context_recall'] > 0.90 else 'Not all'} relevant documents are being retrieved.
- **Faithfulness**: {'Good' if results['faithfulness'] > 0.95 else 'Needs improvement'} - Answers are {'well' if results['faithfulness'] > 0.95 else 'not sufficiently'} grounded in retrieved context.
- **Answer Relevancy**: {'Good' if results['answer_relevancy'] > 0.85 else 'Needs improvement'} - Answers {'address' if results['answer_relevancy'] > 0.85 else 'do not fully address'} the questions asked.
"""
        
        if output_path:
            with open(output_path, 'w') as f:
                f.write(report)
        
        return report
```

### Golden QA Dataset

```python
# evaluation/golden_qa.py

GOLDEN_QA_DATASET = [
    {
        "question": "What was Reliance Industries' revenue in FY2024?",
        "ground_truth": "Reliance Industries reported total revenue of ₹9,74,864 crore in FY2024.",
        "category": "factual",
        "company": "RELIANCE.NS",
        "difficulty": "easy"
    },
    {
        "question": "Compare the P/E ratios of TCS and Infosys for FY2024",
        "ground_truth": "TCS had a P/E ratio of 32.1x while Infosys had a P/E ratio of 28.5x in FY2024, making TCS relatively more expensive.",
        "category": "comparative",
        "company": ["TCS.NS", "INFY.NS"],
        "difficulty": "medium"
    },
    {
        "question": "What were the key growth drivers mentioned in HDFC Bank's FY2024 annual report?",
        "ground_truth": "HDFC Bank's FY2024 annual report highlighted retail lending growth, digital banking adoption, and expansion in semi-urban/rural markets as key growth drivers.",
        "category": "analytical",
        "company": "HDFCBANK.NS",
        "difficulty": "hard"
    },
    # ... 50+ more golden QA pairs
]

def load_golden_qa(
    category: str = None,
    difficulty: str = None,
    company: str = None
) -> List[Dict]:
    """Load golden QA dataset with optional filters"""
    
    data = GOLDEN_QA_DATASET
    
    if category:
        data = [d for d in data if d["category"] == category]
    
    if difficulty:
        data = [d for d in data if d["difficulty"] == difficulty]
    
    if company:
        data = [d for d in data if company in (d["company"] if isinstance(d["company"], list) else [d["company"]])]
    
    return data
```

---

## Agent Trajectory Evaluation

### What is Trajectory Evaluation?

Trajectory evaluation assesses not just the final answer, but the *path* the agent took to get there.

```
Good Trajectory:
  router → retrieve → grade → generate → fact_check → cite → END
  (Direct path, no retries needed)

Suboptimal Trajectory:
  router → retrieve → grade → rewrite → retrieve → grade → generate → fact_check → generate → fact_check → cite → END
  (Multiple retries, indicates issues)
```

### Implementation

```python
# evaluation/trajectory_eval.py

from typing import List, Dict
from dataclasses import dataclass
from enum import Enum

class TrajectoryQuality(Enum):
    OPTIMAL = "optimal"
    ACCEPTABLE = "acceptable"
    SUBOPTIMAL = "suboptimal"
    FAILED = "failed"

@dataclass
class TrajectoryMetrics:
    total_nodes: int
    unique_nodes: int
    retry_count: int
    path_efficiency: float  # unique_nodes / total_nodes
    reached_end: bool
    quality: TrajectoryQuality

class TrajectoryEvaluator:
    """Evaluate agent execution trajectories"""
    
    # Optimal paths for different query types
    REFERENCE_TRAJECTORIES = {
        "factual": ["router", "retrieve", "grade", "generate", "fact_check", "cite", "hitl_check"],
        "comparative": ["router", "retrieve", "grade", "generate", "fact_check", "cite", "hitl_check"],
        "current_events": ["router", "web_search", "generate", "fact_check", "cite", "hitl_check"],
        "direct": ["router", "direct_answer", "hitl_check"]
    }
    
    def evaluate_trajectory(
        self,
        actual_path: List[str],
        query_type: str
    ) -> TrajectoryMetrics:
        """Evaluate a single trajectory"""
        
        reference = self.REFERENCE_TRAJECTORIES.get(query_type, self.REFERENCE_TRAJECTORIES["factual"])
        
        total_nodes = len(actual_path)
        unique_nodes = len(set(actual_path))
        
        # Count retries
        retry_count = actual_path.count("rewrite") + max(0, actual_path.count("generate") - 1)
        
        # Path efficiency
        path_efficiency = unique_nodes / total_nodes if total_nodes > 0 else 0
        
        # Check if reached end
        reached_end = "hitl_check" in actual_path or actual_path[-1] == "cite"
        
        # Determine quality
        if not reached_end:
            quality = TrajectoryQuality.FAILED
        elif retry_count == 0 and path_efficiency > 0.9:
            quality = TrajectoryQuality.OPTIMAL
        elif retry_count <= 1 and path_efficiency > 0.7:
            quality = TrajectoryQuality.ACCEPTABLE
        else:
            quality = TrajectoryQuality.SUBOPTIMAL
        
        return TrajectoryMetrics(
            total_nodes=total_nodes,
            unique_nodes=unique_nodes,
            retry_count=retry_count,
            path_efficiency=path_efficiency,
            reached_end=reached_end,
            quality=quality
        )
    
    def evaluate_batch(
        self,
        trajectories: List[Dict]  # [{path: [...], query_type: "..."}]
    ) -> Dict:
        """Evaluate a batch of trajectories"""
        
        results = [
            self.evaluate_trajectory(t["path"], t["query_type"])
            for t in trajectories
        ]
        
        quality_counts = {q: 0 for q in TrajectoryQuality}
        for r in results:
            quality_counts[r.quality] += 1
        
        return {
            "total": len(results),
            "quality_distribution": {k.value: v for k, v in quality_counts.items()},
            "avg_path_efficiency": sum(r.path_efficiency for r in results) / len(results),
            "avg_retry_count": sum(r.retry_count for r in results) / len(results),
            "success_rate": sum(1 for r in results if r.reached_end) / len(results)
        }
```

---

## LangSmith Integration

### Setup

```python
# observability/langsmith_setup.py

import os
from langsmith import Client
from langchain_core.tracers import LangChainTracer

# Environment setup
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_ENDPOINT"] = "https://api.smith.langchain.com"
os.environ["LANGCHAIN_API_KEY"] = "ls__xxx"
os.environ["LANGCHAIN_PROJECT"] = "nifty50-rag"

# Initialize client
langsmith_client = Client()

def get_tracer(
    project_name: str = "nifty50-rag",
    tags: List[str] = None,
    metadata: Dict = None
) -> LangChainTracer:
    """Get configured LangSmith tracer"""
    
    return LangChainTracer(
        project_name=project_name,
        tags=tags or [],
        metadata=metadata or {}
    )
```

### Custom Trace Logging

```python
# observability/trace_logger.py

from langsmith import traceable
from functools import wraps
import time

def trace_node(node_name: str):
    """Decorator to trace LangGraph nodes"""
    
    def decorator(func):
        @wraps(func)
        @traceable(name=node_name, run_type="chain")
        async def wrapper(state, *args, **kwargs):
            start_time = time.time()
            
            try:
                result = await func(state, *args, **kwargs)
                
                # Log metrics
                duration_ms = (time.time() - start_time) * 1000
                
                return result
            
            except Exception as e:
                # Log error
                raise
        
        return wrapper
    return decorator

# Usage
@trace_node("retrieve")
async def retrieve_node(state: AgenticRAGState) -> dict:
    # ... implementation
    pass
```

### Evaluation with LangSmith

```python
# observability/langsmith_eval.py

from langsmith.evaluation import evaluate, LangChainStringEvaluator
from langsmith import Client

client = Client()

def run_langsmith_evaluation(
    dataset_name: str,
    chain,
    evaluators: List[str] = None
) -> Dict:
    """Run evaluation using LangSmith"""
    
    # Default evaluators
    if evaluators is None:
        evaluators = [
            LangChainStringEvaluator("qa"),  # QA correctness
            LangChainStringEvaluator("context_qa"),  # Context-based QA
            LangChainStringEvaluator("cot_qa"),  # Chain of thought QA
        ]
    
    # Run evaluation
    results = evaluate(
        chain.invoke,
        data=dataset_name,
        evaluators=evaluators,
        experiment_prefix="nifty50-rag-eval"
    )
    
    return results
```

---

## Production Monitoring

### Prometheus Metrics

```python
# monitoring/metrics.py

from prometheus_client import Counter, Histogram, Gauge, Info
import time

# Application info
app_info = Info('nifty50_rag', 'Application information')
app_info.info({
    'version': '1.0.0',
    'environment': os.environ.get('ENVIRONMENT', 'development')
})

# Query metrics
query_total = Counter(
    'rag_queries_total',
    'Total number of queries',
    ['status', 'query_type']
)

query_latency = Histogram(
    'rag_query_latency_seconds',
    'Query latency in seconds',
    ['query_type'],
    buckets=[0.5, 1, 2, 5, 10, 30, 60]
)

# Retrieval metrics
retrieval_latency = Histogram(
    'rag_retrieval_latency_seconds',
    'Retrieval latency in seconds',
    ['search_type'],  # 'vector', 'bm25', 'hybrid'
    buckets=[0.1, 0.25, 0.5, 1, 2, 5]
)

documents_retrieved = Histogram(
    'rag_documents_retrieved',
    'Number of documents retrieved',
    buckets=[0, 1, 5, 10, 20, 50]
)

documents_relevant = Histogram(
    'rag_documents_relevant',
    'Number of relevant documents after grading',
    buckets=[0, 1, 2, 5, 10]
)

# LLM metrics
llm_calls_total = Counter(
    'rag_llm_calls_total',
    'Total LLM API calls',
    ['model', 'node']
)

llm_tokens_total = Counter(
    'rag_llm_tokens_total',
    'Total tokens used',
    ['model', 'direction']  # 'input' or 'output'
)

llm_latency = Histogram(
    'rag_llm_latency_seconds',
    'LLM call latency',
    ['model'],
    buckets=[0.5, 1, 2, 5, 10, 30]
)

# Quality metrics
faithfulness_score = Histogram(
    'rag_faithfulness_score',
    'Faithfulness scores',
    buckets=[0, 0.5, 0.7, 0.8, 0.9, 0.95, 1.0]
)

hallucination_detected = Counter(
    'rag_hallucinations_total',
    'Number of hallucinations detected'
)

# Workflow metrics
workflow_retries = Counter(
    'rag_workflow_retries_total',
    'Number of workflow retries',
    ['retry_type']  # 'rewrite', 'regenerate'
)

hitl_triggered = Counter(
    'rag_hitl_triggered_total',
    'Number of HITL reviews triggered',
    ['reason']
)

# System metrics
active_queries = Gauge(
    'rag_active_queries',
    'Number of currently processing queries'
)

ingestion_queue_size = Gauge(
    'rag_ingestion_queue_size',
    'Number of documents in ingestion queue'
)

vector_index_size = Gauge(
    'rag_vector_index_size',
    'Number of vectors in index'
)
```

### Metrics Collection

```python
# monitoring/collector.py

from contextlib import contextmanager
import time

@contextmanager
def track_query(query_type: str):
    """Context manager to track query metrics"""
    
    active_queries.inc()
    start_time = time.time()
    status = "success"
    
    try:
        yield
    except Exception:
        status = "error"
        raise
    finally:
        duration = time.time() - start_time
        query_total.labels(status=status, query_type=query_type).inc()
        query_latency.labels(query_type=query_type).observe(duration)
        active_queries.dec()

@contextmanager
def track_llm_call(model: str, node: str):
    """Context manager to track LLM calls"""
    
    start_time = time.time()
    
    try:
        yield
    finally:
        duration = time.time() - start_time
        llm_calls_total.labels(model=model, node=node).inc()
        llm_latency.labels(model=model).observe(duration)

def record_tokens(model: str, input_tokens: int, output_tokens: int):
    """Record token usage"""
    llm_tokens_total.labels(model=model, direction="input").inc(input_tokens)
    llm_tokens_total.labels(model=model, direction="output").inc(output_tokens)

def record_retrieval(search_type: str, num_retrieved: int, num_relevant: int, latency: float):
    """Record retrieval metrics"""
    retrieval_latency.labels(search_type=search_type).observe(latency)
    documents_retrieved.observe(num_retrieved)
    documents_relevant.observe(num_relevant)

def record_quality(faithfulness: float, has_hallucination: bool):
    """Record quality metrics"""
    faithfulness_score.observe(faithfulness)
    if has_hallucination:
        hallucination_detected.inc()
```

### Grafana Dashboards

```json
// monitoring/grafana/dashboards/rag-overview.json

{
  "dashboard": {
    "title": "NIFTY 50 RAG - Overview",
    "panels": [
      {
        "title": "Query Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(rag_queries_total[5m])",
            "legendFormat": "{{status}}"
          }
        ]
      },
      {
        "title": "Query Latency (p95)",
        "type": "stat",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(rag_query_latency_seconds_bucket[5m]))"
          }
        ]
      },
      {
        "title": "Faithfulness Score Distribution",
        "type": "heatmap",
        "targets": [
          {
            "expr": "rate(rag_faithfulness_score_bucket[1h])"
          }
        ]
      },
      {
        "title": "Hallucination Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "rate(rag_hallucinations_total[1h]) / rate(rag_queries_total[1h])"
          }
        ]
      },
      {
        "title": "LLM Token Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(rag_llm_tokens_total[5m])) by (model, direction)"
          }
        ]
      },
      {
        "title": "Active Queries",
        "type": "gauge",
        "targets": [
          {
            "expr": "rag_active_queries"
          }
        ]
      }
    ]
  }
}
```

---

## Alerting Rules

```yaml
# monitoring/alerts/rag-alerts.yml

groups:
  - name: rag-alerts
    rules:
      # High error rate
      - alert: HighQueryErrorRate
        expr: rate(rag_queries_total{status="error"}[5m]) / rate(rag_queries_total[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High query error rate"
          description: "Query error rate is {{ $value | humanizePercentage }} over the last 5 minutes"
      
      # High latency
      - alert: HighQueryLatency
        expr: histogram_quantile(0.95, rate(rag_query_latency_seconds_bucket[5m])) > 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High query latency"
          description: "P95 query latency is {{ $value | humanizeDuration }}"
      
      # High hallucination rate
      - alert: HighHallucinationRate
        expr: rate(rag_hallucinations_total[1h]) / rate(rag_queries_total[1h]) > 0.02
        for: 15m
        labels:
          severity: critical
        annotations:
          summary: "High hallucination rate"
          description: "Hallucination rate is {{ $value | humanizePercentage }}"
      
      # Low faithfulness
      - alert: LowFaithfulnessScore
        expr: avg(rag_faithfulness_score) < 0.9
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: "Low average faithfulness score"
          description: "Average faithfulness is {{ $value }}"
      
      # HITL queue buildup
      - alert: HITLQueueBacklog
        expr: rag_hitl_pending > 10
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "HITL review queue is building up"
          description: "{{ $value }} reviews pending"
      
      # Ingestion failures
      - alert: IngestionFailures
        expr: rate(ingestion_documents_total{status="failed"}[1h]) > 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Document ingestion failures"
          description: "{{ $value }} documents failed ingestion"
      
      # Vector index size
      - alert: VectorIndexSizeAnomaly
        expr: abs(rag_vector_index_size - avg_over_time(rag_vector_index_size[24h])) / avg_over_time(rag_vector_index_size[24h]) > 0.1
        for: 1h
        labels:
          severity: info
        annotations:
          summary: "Vector index size changed significantly"
```

---

## Automated Testing

### CI Evaluation Pipeline

```yaml
# .github/workflows/evaluation.yml

name: RAG Evaluation

on:
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM UTC
  workflow_dispatch:

jobs:
  evaluate:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install ragas langsmith
      
      - name: Run RAGAS Evaluation
        env:
          GROQ_API_KEY: ${{ secrets.GROQ_API_KEY }}
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          LANGCHAIN_API_KEY: ${{ secrets.LANGSMITH_API_KEY }}
        run: |
          python -m evaluation.run_evaluation \
            --dataset golden_qa \
            --output results/evaluation_$(date +%Y%m%d).json
      
      - name: Check Thresholds
        run: |
          python -m evaluation.check_thresholds \
            --results results/evaluation_$(date +%Y%m%d).json \
            --min-faithfulness 0.95 \
            --min-context-recall 0.90 \
            --max-hallucination-rate 0.02
      
      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: evaluation-results
          path: results/
      
      - name: Notify on Failure
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "⚠️ RAG Evaluation Failed - Check GitHub Actions"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## Next Document

Continue to [10-IMPLEMENTATION-ROADMAP.md](./10-IMPLEMENTATION-ROADMAP.md) for the implementation timeline.

