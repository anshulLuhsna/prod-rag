# Environment Variables Reference

## Required Variables

### Database

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:5432/db` |
| `DB_HOST` | Database host (for Cloud SQL) | `10.0.0.5` |
| `DB_PASSWORD` | Database password | `secure-password` |

### Redis

| Variable | Description | Example |
|----------|-------------|---------|
| `REDIS_URL` | Redis connection string | `redis://localhost:6379/0` |

### Qdrant

| Variable | Description | Example |
|----------|-------------|---------|
| `QDRANT_HOST` | Qdrant server host | `localhost` |
| `QDRANT_PORT` | Qdrant REST port | `6333` |
| `QDRANT_API_KEY` | API key (if using Qdrant Cloud) | `xxx` |

### LLM APIs

| Variable | Description | Example |
|----------|-------------|---------|
| `GROQ_API_KEY` | Groq API key | `gsk_xxx` |
| `OPENAI_API_KEY` | OpenAI API key (for embeddings) | `sk-xxx` |
| `LLAMA_CLOUD_API_KEY` | LlamaParse API key | `llx-xxx` |

### GCP

| Variable | Description | Example |
|----------|-------------|---------|
| `GCP_PROJECT_ID` | GCP project ID | `my-project-123` |
| `GCS_BUCKET` | Cloud Storage bucket name | `nifty50-rag-documents` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to service account JSON | `/path/to/sa.json` |

### Observability

| Variable | Description | Example |
|----------|-------------|---------|
| `LANGCHAIN_TRACING_V2` | Enable LangSmith tracing | `true` |
| `LANGCHAIN_API_KEY` | LangSmith API key | `ls__xxx` |
| `LANGCHAIN_PROJECT` | LangSmith project name | `nifty50-rag` |
| `LANGCHAIN_ENDPOINT` | LangSmith endpoint | `https://api.smith.langchain.com` |

### Security

| Variable | Description | Example |
|----------|-------------|---------|
| `JWT_SECRET_KEY` | Secret for JWT signing | `your-256-bit-secret` |
| `JWT_ALGORITHM` | JWT algorithm | `HS256` |
| `JWT_EXPIRE_MINUTES` | Token expiration | `60` |

### Application

| Variable | Description | Example |
|----------|-------------|---------|
| `ENVIRONMENT` | Environment name | `production` |
| `DEBUG` | Enable debug mode | `false` |
| `LOG_LEVEL` | Logging level | `INFO` |

---

## Optional Variables

### External Services

| Variable | Description | Default |
|----------|-------------|---------|
| `TAVILY_API_KEY` | Tavily search API key | - |
| `COHERE_API_KEY` | Cohere reranker API key | - |

### Rate Limiting

| Variable | Description | Default |
|----------|-------------|---------|
| `RATE_LIMIT_QUERIES_PER_DAY` | Max queries per user per day | `100` |
| `RATE_LIMIT_REQUESTS_PER_HOUR` | Max API requests per hour | `1000` |

### Caching

| Variable | Description | Default |
|----------|-------------|---------|
| `CACHE_TTL_QUERIES` | Query cache TTL (seconds) | `3600` |
| `CACHE_TTL_EMBEDDINGS` | Embedding cache TTL (seconds) | `86400` |

---

## Sample .env File

```bash
# .env.example

# Database
DATABASE_URL=postgresql://app:password@localhost:5432/nifty50_rag
DB_HOST=localhost
DB_PASSWORD=your-db-password

# Redis
REDIS_URL=redis://localhost:6379/0

# Qdrant
QDRANT_HOST=localhost
QDRANT_PORT=6333

# LLM APIs
GROQ_API_KEY=gsk_xxx
OPENAI_API_KEY=sk-xxx
LLAMA_CLOUD_API_KEY=llx-xxx

# GCP
GCP_PROJECT_ID=your-project-id
GCS_BUCKET=nifty50-rag-documents

# Observability
LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=ls__xxx
LANGCHAIN_PROJECT=nifty50-rag

# Security
JWT_SECRET_KEY=your-super-secret-key-at-least-32-chars
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=60

# Application
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=DEBUG
```

---

## Secret Management (GCP)

For production, use GCP Secret Manager:

```bash
# Create secrets
gcloud secrets create db-password --data-file=- <<< "your-password"
gcloud secrets create groq-api-key --data-file=- <<< "gsk_xxx"
gcloud secrets create openai-api-key --data-file=- <<< "sk-xxx"
gcloud secrets create llama-cloud-api-key --data-file=- <<< "llx-xxx"
gcloud secrets create jwt-secret-key --data-file=- <<< "your-jwt-secret"

# Access secrets in application
gcloud secrets versions access latest --secret="db-password"
```

---

## Docker Compose Environment

```yaml
# docker-compose.yml
services:
  backend:
    environment:
      - DATABASE_URL=postgresql://app:${DB_PASSWORD}@${DB_HOST}:5432/nifty50_rag
      - REDIS_URL=redis://redis:6379/0
      - QDRANT_HOST=qdrant
      - QDRANT_PORT=6333
      - GROQ_API_KEY=${GROQ_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - LLAMA_CLOUD_API_KEY=${LLAMA_CLOUD_API_KEY}
      - GCS_BUCKET=${GCS_BUCKET}
      - LANGCHAIN_TRACING_V2=true
      - LANGCHAIN_API_KEY=${LANGSMITH_API_KEY}
      - LANGCHAIN_PROJECT=nifty50-rag
      - JWT_SECRET_KEY=${JWT_SECRET_KEY}
      - ENVIRONMENT=${ENVIRONMENT:-production}
```

