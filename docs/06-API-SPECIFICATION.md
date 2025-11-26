# 06 - API Specification

## Overview

The FastAPI backend provides REST APIs for:
- Query processing (RAG workflow)
- Company data access
- Document management
- Human-in-the-loop workflows
- System administration

Base URL: `https://api.nifty50rag.com/api/v1`

---

## Authentication

### JWT Token Flow

```
POST /auth/login
    ↓
{ access_token, refresh_token }
    ↓
Authorization: Bearer {access_token}
    ↓
POST /auth/refresh (when expired)
```

### Endpoints

#### Login
```http
POST /auth/login
Content-Type: application/json

{
    "email": "user@example.com",
    "password": "securepassword"
}
```

**Response (200)**:
```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "bearer",
    "expires_in": 3600
}
```

#### Refresh Token
```http
POST /auth/refresh
Content-Type: application/json

{
    "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

#### Get Current User
```http
GET /auth/me
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "user",
    "daily_query_limit": 100,
    "queries_today": 15
}
```

---

## Query Endpoints

### Submit Query

```http
POST /query
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "question": "What was Reliance's revenue in FY2024?",
    "filters": {
        "company_symbol": "RELIANCE.NS",
        "fiscal_period": "FY2024",
        "document_types": ["annual_report", "quarterly_result"]
    },
    "stream": false
}
```

**Response (200)**:
```json
{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "question": "What was Reliance's revenue in FY2024?",
    "response": "According to Reliance Industries' FY2024 Annual Report, the company reported total revenue of ₹9,74,864 crore [1], representing a growth of 2.6% compared to FY2023...",
    "citations": [
        {
            "index": 1,
            "document_id": 123,
            "document_title": "Reliance Industries Annual Report FY2024",
            "source_text": "Total revenue from operations for FY2024 was ₹9,74,864 crore...",
            "page_number": 45
        }
    ],
    "status": "completed",
    "latency_ms": 3420,
    "created_at": "2024-11-25T10:30:00Z"
}
```

### Stream Query

```http
POST /query/stream
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "question": "Compare TCS and Infosys revenue growth",
    "stream": true
}
```

**Response (200 - Server-Sent Events)**:
```
event: node
data: {"node": "router", "status": "completed", "route": "vector_store"}

event: node
data: {"node": "retrieve", "status": "completed", "documents_found": 8}

event: node
data: {"node": "grade", "status": "completed", "relevant_count": 5}

event: token
data: {"content": "Based on"}

event: token
data: {"content": " the financial"}

event: token
data: {"content": " reports..."}

event: citation
data: {"index": 1, "document_title": "TCS Annual Report FY2024"}

event: done
data: {"id": "550e8400-e29b-41d4-a716-446655440000", "latency_ms": 5230}
```

### Get Query Result

```http
GET /query/{query_id}
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "question": "What was Reliance's revenue in FY2024?",
    "response": "...",
    "citations": [...],
    "status": "completed",
    "workflow_trace": {
        "nodes_executed": ["router", "retrieve", "grade", "generate", "fact_check", "cite"],
        "rewrite_count": 0,
        "generation_attempts": 1
    },
    "metrics": {
        "latency_ms": 3420,
        "token_count_input": 2500,
        "token_count_output": 350,
        "retrieval_score": 0.89,
        "faithfulness_score": 0.95
    },
    "created_at": "2024-11-25T10:30:00Z",
    "completed_at": "2024-11-25T10:30:03Z"
}
```

### Query History

```http
GET /query/history?limit=20&offset=0
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "total": 150,
    "limit": 20,
    "offset": 0,
    "queries": [
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "question": "What was Reliance's revenue in FY2024?",
            "status": "completed",
            "latency_ms": 3420,
            "created_at": "2024-11-25T10:30:00Z"
        }
    ]
}
```

### Submit Feedback

```http
POST /query/{query_id}/feedback
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "rating": 5,
    "feedback": "Very accurate and well-cited answer"
}
```

---

## Company Endpoints

### List Companies

```http
GET /companies?sector=Banking&limit=50
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "total": 50,
    "companies": [
        {
            "id": 1,
            "symbol": "RELIANCE.NS",
            "name": "Reliance Industries Ltd",
            "sector": "Energy",
            "industry": "Oil & Gas Refining",
            "market_cap_rank": 1
        },
        {
            "id": 2,
            "symbol": "HDFCBANK.NS",
            "name": "HDFC Bank Ltd",
            "sector": "Banking",
            "industry": "Private Banks",
            "market_cap_rank": 2
        }
    ]
}
```

### Get Company Details

```http
GET /companies/RELIANCE.NS
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "id": 1,
    "symbol": "RELIANCE.NS",
    "name": "Reliance Industries Ltd",
    "sector": "Energy",
    "industry": "Oil & Gas Refining",
    "market_cap_rank": 1,
    "isin": "INE002A01018",
    "nse_symbol": "RELIANCE",
    "bse_code": "500325",
    "website": "https://www.ril.com",
    "ir_page_url": "https://www.ril.com/investors",
    "latest_fundamentals": {
        "period": "Q2FY25",
        "revenue": 258027000000000,
        "net_income": 19101000000000,
        "eps": 141.56,
        "pe_ratio": 25.3,
        "market_cap": 19500000000000000
    },
    "latest_price": {
        "date": "2024-11-25",
        "close": 2850.50,
        "change_percent": 1.25
    }
}
```

### Get Company Fundamentals

```http
GET /companies/RELIANCE.NS/fundamentals?period_type=quarterly&limit=8
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "symbol": "RELIANCE.NS",
    "fundamentals": [
        {
            "period": "Q2FY25",
            "period_type": "quarterly",
            "period_end_date": "2024-09-30",
            "revenue": 258027000000000,
            "net_income": 19101000000000,
            "eps": 141.56,
            "pe_ratio": 25.3,
            "roe": 0.089,
            "debt_to_equity": 0.42
        }
    ]
}
```

### Get Company Prices

```http
GET /companies/RELIANCE.NS/prices?from=2024-01-01&to=2024-11-25
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "symbol": "RELIANCE.NS",
    "prices": [
        {
            "date": "2024-11-25",
            "open": 2830.00,
            "high": 2865.00,
            "low": 2820.00,
            "close": 2850.50,
            "volume": 5234567
        }
    ]
}
```

### Get Company Documents

```http
GET /companies/RELIANCE.NS/documents?doc_type=annual_report
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "symbol": "RELIANCE.NS",
    "documents": [
        {
            "id": 123,
            "doc_type": "annual_report",
            "title": "Annual Report FY2024",
            "fiscal_period": "FY2024",
            "document_date": "2024-05-15",
            "status": "completed",
            "chunk_count": 450,
            "download_url": "/documents/123/download"
        }
    ]
}
```

### Get Company News

```http
GET /companies/RELIANCE.NS/news?limit=10
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "symbol": "RELIANCE.NS",
    "news": [
        {
            "id": 5678,
            "title": "Reliance Q2 profit rises 5% to ₹19,101 crore",
            "source": "Economic Times",
            "url": "https://economictimes.com/...",
            "summary": "Reliance Industries reported a 5% increase...",
            "sentiment": "positive",
            "sentiment_score": 0.72,
            "published_at": "2024-11-25T09:00:00Z"
        }
    ]
}
```

---

## Document Endpoints

### List Documents

```http
GET /documents?status=completed&doc_type=annual_report&limit=50
Authorization: Bearer {access_token}
```

### Get Document

```http
GET /documents/{document_id}
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "id": 123,
    "company_id": 1,
    "company_symbol": "RELIANCE.NS",
    "doc_type": "annual_report",
    "title": "Annual Report FY2024",
    "fiscal_period": "FY2024",
    "document_date": "2024-05-15",
    "status": "completed",
    "chunk_count": 450,
    "storage_path": "gs://nifty50-rag/documents/reliance/annual_report_fy2024.pdf",
    "file_size_bytes": 15234567,
    "page_count": 234,
    "created_at": "2024-05-20T10:00:00Z"
}
```

### Download Document

```http
GET /documents/{document_id}/download
Authorization: Bearer {access_token}
```

**Response**: Binary PDF file with appropriate headers

### Trigger Ingestion

```http
POST /documents/ingest
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "company_symbol": "RELIANCE.NS",
    "doc_type": "annual_report",
    "source_url": "https://www.ril.com/annual-report-2024.pdf",
    "fiscal_period": "FY2024"
}
```

**Response (202)**:
```json
{
    "document_id": 124,
    "status": "pending",
    "message": "Document queued for ingestion"
}
```

### Get Ingestion Status

```http
GET /documents/{document_id}/ingestion-status
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "document_id": 124,
    "status": "processing",
    "progress": {
        "download": "completed",
        "parse": "completed",
        "chunk": "in_progress",
        "embed": "pending",
        "index": "pending"
    },
    "started_at": "2024-11-25T10:00:00Z",
    "estimated_completion": "2024-11-25T10:05:00Z"
}
```

---

## HITL Endpoints

### List Pending Reviews

```http
GET /hitl/pending
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "total": 3,
    "reviews": [
        {
            "id": "review-uuid-1",
            "query_id": "query-uuid-1",
            "question": "What is the fraud investigation status at XYZ?",
            "generated_response": "...",
            "reason": "Sensitive topic detected",
            "created_at": "2024-11-25T10:30:00Z",
            "expires_at": "2024-11-25T11:30:00Z"
        }
    ]
}
```

### Get Review Details

```http
GET /hitl/{review_id}
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "id": "review-uuid-1",
    "query_id": "query-uuid-1",
    "question": "What is the fraud investigation status at XYZ?",
    "generated_response": "Based on the documents...",
    "citations": [...],
    "reason": "Sensitive topic detected",
    "workflow_state": {
        "nodes_executed": ["router", "retrieve", "grade", "generate"],
        "fact_check_result": {
            "is_faithful": true,
            "confidence": 0.65
        }
    },
    "created_at": "2024-11-25T10:30:00Z"
}
```

### Approve Review

```http
POST /hitl/{review_id}/approve
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "notes": "Response is accurate and appropriate"
}
```

**Response (200)**:
```json
{
    "id": "review-uuid-1",
    "status": "approved",
    "reviewed_by": "admin@example.com",
    "reviewed_at": "2024-11-25T10:35:00Z"
}
```

### Reject Review

```http
POST /hitl/{review_id}/reject
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "notes": "Response contains unverified claims"
}
```

### Edit and Approve

```http
POST /hitl/{review_id}/edit
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "edited_response": "The corrected response text...",
    "notes": "Removed speculative claims"
}
```

---

## Admin Endpoints

### System Health

```http
GET /admin/health
```

**Response (200)**:
```json
{
    "status": "healthy",
    "services": {
        "database": "healthy",
        "qdrant": "healthy",
        "redis": "healthy",
        "celery": "healthy"
    },
    "version": "1.0.0",
    "uptime_seconds": 86400
}
```

### Ingestion Stats

```http
GET /admin/stats/ingestion
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "total_documents": 550,
    "by_status": {
        "completed": 540,
        "processing": 5,
        "failed": 5
    },
    "by_type": {
        "annual_report": 150,
        "quarterly_result": 350,
        "news_article": 50
    },
    "total_chunks": 125000,
    "last_24h": {
        "documents_ingested": 25,
        "news_articles": 150
    }
}
```

### Query Stats

```http
GET /admin/stats/queries?period=7d
Authorization: Bearer {access_token}
```

**Response (200)**:
```json
{
    "period": "7d",
    "total_queries": 1500,
    "avg_latency_ms": 3200,
    "p95_latency_ms": 8500,
    "by_status": {
        "completed": 1450,
        "failed": 30,
        "hitl_pending": 20
    },
    "avg_faithfulness_score": 0.92,
    "avg_relevance_score": 0.88
}
```

### Trigger Bootstrap

```http
POST /admin/bootstrap
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "companies": ["RELIANCE.NS", "TCS.NS"],
    "doc_types": ["annual_report"],
    "years": [2024, 2023, 2022]
}
```

**Response (202)**:
```json
{
    "task_id": "bootstrap-task-uuid",
    "status": "started",
    "estimated_documents": 6
}
```

---

## Error Responses

### Standard Error Format

```json
{
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Invalid request parameters",
        "details": [
            {
                "field": "question",
                "message": "Question must be at least 10 characters"
            }
        ]
    },
    "request_id": "req-uuid-123"
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid request parameters |
| `UNAUTHORIZED` | 401 | Missing or invalid auth token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily unavailable |

---

## Rate Limiting

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/query` | 100 | per day per user |
| `/query/stream` | 50 | per day per user |
| `/companies/*` | 1000 | per hour |
| `/documents/*` | 500 | per hour |
| `/admin/*` | 100 | per hour |

**Rate Limit Headers**:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 85
X-RateLimit-Reset: 1732550400
```

---

## OpenAPI Schema

The full OpenAPI 3.0 specification is available at:
- Swagger UI: `GET /docs`
- ReDoc: `GET /redoc`
- OpenAPI JSON: `GET /openapi.json`

---

## Next Document

Continue to [07-FRONTEND-SPEC.md](./07-FRONTEND-SPEC.md) for frontend specification.

