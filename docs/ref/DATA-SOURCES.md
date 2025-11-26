# Data Sources Reference

## Overview

This document catalogs all data sources used in the NIFTY 50 Agentic RAG system.

---

## Document Sources

### 1. Annual Reports

| Source | URL Pattern | Format | Auth |
|--------|-------------|--------|------|
| NSE Corporate Filings | `nseindia.com/companies-listing/corporate-filings-annual-reports` | PDF | None |
| BSE Corporate Filings | `bseindia.com/corporates/ann.html` | PDF | None |
| Company IR Pages | Varies by company | PDF | None |

**NSE API Endpoint:**
```
GET https://www.nseindia.com/api/corporate-announcements
Parameters:
  - index: equities
  - symbol: RELIANCE
  - subject: Annual Report
  - from_date: 01-01-2024
  - to_date: 31-12-2024
```

**Headers Required:**
```python
headers = {
    "User-Agent": "Mozilla/5.0",
    "Accept": "application/json",
    "Accept-Language": "en-US,en;q=0.9",
    "Referer": "https://www.nseindia.com/"
}
```

---

### 2. Quarterly Results

| Source | URL Pattern | Format | Auth |
|--------|-------------|--------|------|
| NSE Announcements | `nseindia.com/api/corporate-announcements` | PDF | None |
| BSE Announcements | `bseindia.com/corporates/ann.html` | PDF | None |

**NSE API for Quarterly Results:**
```
GET https://www.nseindia.com/api/corporate-announcements
Parameters:
  - index: equities
  - symbol: TCS
  - subject: Financial Results
  - from_date: 01-01-2024
  - to_date: 31-12-2024
```

---

### 3. News Articles

#### RSS Feeds

| Source | Feed URL | Category |
|--------|----------|----------|
| Economic Times Markets | `economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms` | Markets |
| Economic Times Companies | `economictimes.indiatimes.com/news/company/rssfeeds/2143429.cms` | Companies |
| Moneycontrol Markets | `moneycontrol.com/rss/marketreports.xml` | Markets |
| Moneycontrol News | `moneycontrol.com/rss/latestnews.xml` | General |
| Business Standard | `business-standard.com/rss/markets-106.rss` | Markets |
| Livemint | `livemint.com/rss/markets` | Markets |

**RSS Parsing Example:**
```python
import feedparser

def fetch_news(feed_url: str) -> List[dict]:
    feed = feedparser.parse(feed_url)
    articles = []
    for entry in feed.entries:
        articles.append({
            "title": entry.title,
            "link": entry.link,
            "summary": entry.get("summary", ""),
            "published": entry.get("published", ""),
            "source": feed.feed.title
        })
    return articles
```

---

## Market Data Sources

### 4. Stock Prices (yfinance)

| Data | Frequency | Retention |
|------|-----------|-----------|
| OHLCV | Daily | 3 years |
| Intraday | Not used | - |

**API Usage:**
```python
import yfinance as yf

def fetch_prices(symbol: str, period: str = "3y") -> pd.DataFrame:
    ticker = yf.Ticker(symbol)
    df = ticker.history(period=period)
    return df[['Open', 'High', 'Low', 'Close', 'Volume']]

# Example
prices = fetch_prices("RELIANCE.NS")
```

**Rate Limits:**
- No official limit, but recommend 1 request/second
- Use batching for multiple symbols

---

### 5. Fundamentals (yfinance)

| Metric | Source Field | Update Frequency |
|--------|--------------|------------------|
| Market Cap | `marketCap` | Real-time |
| P/E Ratio | `trailingPE` | Daily |
| P/B Ratio | `priceToBook` | Daily |
| ROE | `returnOnEquity` | Quarterly |
| Debt/Equity | `debtToEquity` | Quarterly |
| Revenue | `totalRevenue` | Quarterly |
| Net Income | `netIncome` | Quarterly |
| EPS | `trailingEps` | Quarterly |
| Dividend Yield | `dividendYield` | Daily |

**API Usage:**
```python
def fetch_fundamentals(symbol: str) -> dict:
    ticker = yf.Ticker(symbol)
    info = ticker.info
    
    return {
        "market_cap": info.get("marketCap"),
        "pe_ratio": info.get("trailingPE"),
        "pb_ratio": info.get("priceToBook"),
        "roe": info.get("returnOnEquity"),
        "debt_to_equity": info.get("debtToEquity"),
        "revenue": info.get("totalRevenue"),
        "net_income": info.get("netIncome"),
        "eps": info.get("trailingEps"),
        "dividend_yield": info.get("dividendYield"),
        "book_value": info.get("bookValue"),
        "52_week_high": info.get("fiftyTwoWeekHigh"),
        "52_week_low": info.get("fiftyTwoWeekLow")
    }
```

---

### 6. Fundamentals (Screener.in) - Supplementary

| Data | URL Pattern | Auth |
|------|-------------|------|
| Company Overview | `screener.in/company/{SYMBOL}/` | None |
| Financial Statements | `screener.in/company/{SYMBOL}/consolidated/` | None |

**Scraping Notes:**
- Rate limit: 1 request per 2 seconds
- Use session cookies for better reliability
- Parse HTML tables for financial data

---

## External APIs

### 7. LlamaParse (Document Parsing)

| Endpoint | Purpose | Rate Limit |
|----------|---------|------------|
| `/api/parsing/upload` | Upload PDF | 100/hour |
| `/api/parsing/job/{id}` | Check status | 1000/hour |
| `/api/parsing/job/{id}/result` | Get result | 1000/hour |

**Configuration:**
```python
from llama_parse import LlamaParse

parser = LlamaParse(
    api_key=os.environ["LLAMA_CLOUD_API_KEY"],
    result_type="markdown",
    output_tables_as_HTML=True,
    spreadsheet_extract_sub_tables=True
)
```

---

### 8. Groq (LLM Inference)

| Model | Context | Rate Limit |
|-------|---------|------------|
| llama-3.3-70b-versatile | 128K | 30 RPM |
| llama-3.1-8b-instant | 128K | 30 RPM |
| mixtral-8x7b-32768 | 32K | 30 RPM |

**Usage:**
```python
from langchain_groq import ChatGroq

llm = ChatGroq(
    model="llama-3.3-70b-versatile",
    temperature=0,
    api_key=os.environ["GROQ_API_KEY"]
)
```

---

### 9. OpenAI (Embeddings)

| Model | Dimensions | Rate Limit |
|-------|------------|------------|
| text-embedding-3-large | 3072 | 3000 RPM |
| text-embedding-3-small | 1536 | 3000 RPM |

**Usage:**
```python
from openai import OpenAI

client = OpenAI()

response = client.embeddings.create(
    model="text-embedding-3-large",
    input=texts,
    dimensions=3072
)
```

---

### 10. Tavily (Web Search - Fallback)

| Endpoint | Purpose | Rate Limit |
|----------|---------|------------|
| `/search` | Web search | 1000/month (free) |

**Usage:**
```python
from langchain_community.tools.tavily_search import TavilySearchResults

search = TavilySearchResults(max_results=5)
results = search.invoke("latest NIFTY 50 news")
```

---

## Data Collection Schedule

| Task | Schedule | Data Source |
|------|----------|-------------|
| News Collection | Every 5 minutes | RSS Feeds |
| Price Update | Daily 6:30 PM IST | yfinance |
| Fundamentals Update | Weekly (Sunday) | yfinance |
| New Filings Check | Every 30 minutes | NSE/BSE |
| Annual Report Check | Daily (Apr-May) | NSE/Company IR |
| Quarterly Result Check | Daily (Jan, Apr, Jul, Oct) | NSE |

---

## Error Handling

### Common Issues

| Issue | Source | Resolution |
|-------|--------|------------|
| 403 Forbidden | NSE | Rotate User-Agent, add delays |
| Rate Limited | yfinance | Implement exponential backoff |
| PDF Parse Error | LlamaParse | Retry with different settings |
| Empty Response | RSS | Check feed URL, retry |

### Retry Configuration

```python
RETRY_CONFIG = {
    "nse": {
        "max_retries": 3,
        "backoff_factor": 2,
        "retry_codes": [403, 429, 500, 502, 503]
    },
    "yfinance": {
        "max_retries": 3,
        "backoff_factor": 1,
        "retry_codes": [429, 500]
    },
    "llamaparse": {
        "max_retries": 2,
        "backoff_factor": 5,
        "retry_codes": [429, 500, 502]
    }
}
```

---

## Data Quality Checks

| Check | Frequency | Action on Failure |
|-------|-----------|-------------------|
| Price data completeness | Daily | Alert + retry |
| Document hash uniqueness | On ingest | Skip duplicate |
| Fundamental data range | Weekly | Flag outliers |
| News article freshness | Hourly | Alert if >1h stale |

