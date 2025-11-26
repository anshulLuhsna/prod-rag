**Complete** **Data** **Collection** **Strategy** **for** **NIFTY**
**50** **Financial** **RAG** **MVP**

**Comprehensive** **Guide** **to** **Acquiring,** **Processing,**
**and** **Ingesting** **All** **Required** **Documents**

**Executive** **Summary**

This document provides a **complete** **blueprint** for collecting all
necessary documents and financial data for your NIFTY 50-focused
financial analysis agent MVP. It covers:

> **Data** **Sources** (real-time & historical)
>
> **Collection** **Methods** (APIs, web scraping, direct downloads)
>
> **Processing** **Pipeline** (parsing, chunking, deduplication)
>
> **Storage** **Strategy** (vector DB + SQL)
>
> **Implementation** **Timeline** (4-week execution plan)
>
> **Code** **Examples** (ready-to-use scripts)

**Target** **Scope**: 50 NIFTY 50 companies, ~2 years historical data,
real-time ingestion

**Estimated** **Data** **Volume**: 5,000-10,000 documents, ~1-2GB total

**Part** **1:** **Complete** **Data** **Source** **Inventory**

**1.1** **Data** **Categories** **&** **Sources** **Matrix**

||
||
||
||
||
||
||
||
||
||
||
||
||

**1.2** **Detailed** **Source** **Breakdown**

**Real-Time** **Financial** **Data**

**Source** **1:** **Upstox** **API** **(Recommended** **for** **MVP)**

> **Coverage**: All NSE/BSE stocks including NIFTY 50
>
> **Data**: Last traded price, OHLC, volume, bid-ask
>
> **Frequency**: Real-time (tick-by-tick)
>
> **Cost**: Free tier available
>
> **Integration**: Simple RESTAPI, Python SDK available
>
> **Endpoint**: https://api2.upstox.com/v2/market-quote/ltp
>
> import upstox_client
>
> \# Get NIFTY 50 real-time data client = upstox_client.ApiClient()
>
> market_data_api = upstox_client.MarketDataApi(client)
>
> \# For each NIFTY 50 symbol
>
> symbols = \['NSE_EQ\|INE002A01018', 'NSE_EQ\|INE022A01019', ...\] \#
> RELIANCE, HDFC, etc response = market_data_api.market_quote(symbols)

**Source** **2:** **Finnhub** **(Alternative)**

> **Coverage**: Global + Indian stocks
>
> **Data**: Real-time quotes, company news
>
> **Cost**: Free tier (100 API calls/min)
>
> **Advantages**: Includes news API in same platform

**Daily** **Price** **&** **Fundamental** **Data**

**Source:** **yfinance** **(Python** **library)**

> **Coverage**: All NSE/BSE stocks
>
> **Data**: OHLC, volume, fundamentals (PE, PB, ROE, etc.)
>
> **Cost**: Free
>
> **Reliability**: Stable, widely used
>
> import yfinance as yf
>
> \# Download NIFTY 50 fundamentals
>
> symbols = \['RELIANCE.NS', 'HDFC.NS', 'ICICIBANK.NS', ...\]
>
> for symbol in symbols:
>
> stock = yf.Ticker(symbol)
>
> \# Get financials financials = {
>
> 'market_cap': stock.info.get('marketCap'), 'pe_ratio':
> stock.info.get('trailingPE'), 'pb_ratio':
> stock.info.get('priceToBook'), 'roe':
> stock.info.get('returnOnEquity'),
>
> 'debt_to_equity': stock.info.get('debtToEquity'), 'revenue':
> stock.info.get('totalRevenue'), 'net_income':
> stock.info.get('netIncome')
>
> }
>
> \# Get historical data
>
> hist = yf.download(symbol, start='2023-01-01', end='2025-11-25')

**Document** **Sources**

**Source** **1:** **NSE** **Corporate** **Filings** **(Official)**

> **URL**:
> [<u>https://www.nseindia.com/companies-listing/corporate-filings-annual-reports</u>](https://www.nseindia.com/companies-listing/corporate-filings-annual-reports)
>
> **Contains**: Annual reports, quarterly results, board notices
>
> **How** **to** **Access**:
>
> Manual download per company
>
> Bulk scraping with rate limiting
>
> **Format**: PDF mostly, some HTML

**Source** **2:** **NSE** **Announcements** **(Real-Time)**

> **URL**:
> [<u>https://www.nseindia.com/market-data/live-equity-market</u>](https://www.nseindia.com/market-data/live-equity-market)
>
> **Contains**: Corporate announcements, regulatory filings
>
> **Update** **Frequency**: Real-time during market hours
>
> **Scraping**: RSS feed available
>
> import requests
>
> from bs4 import BeautifulSoup
>
> def fetch_nse_announcements():
>
> """Scrape latest NSE announcements"""
>
> url = "https://www.nseindia.com/market-data/live-equity-market"
>
> headers = {
>
> 'User-Agent': 'Mozilla/5.0' }
>
> response = requests.get(url, headers=headers)
>
> soup = BeautifulSoup(response.content, 'html.parser')
>
> \# Parse announcement table announcements = \[\]
>
> for row in soup.find_all('tr', class\_='announcement'): link =
> row.find('a')
>
> date = row.find('td', class\_='date').text company = row.find('td',
> class\_='company').text
>
> announcements.append({ 'company': company, 'date': date,
>
> 'pdf_url': link.get('href'), 'title': link.text
>
> })
>
> return announcements

**Source** **3:** [<u>Screener.in</u>](http://screener.in/)
**(Fundamentals** **+** **Historical)**

> **URL**: [<u>https://www.screener.in</u>](https://www.screener.in/)
>
> **Contains**: Financial data, balance sheets, P&L, cash flow
>
> **Coverage**: 10-12 years historical
>
> **How** **to** **Access**:
>
> Download Excel sheets per company
>
> Web scraping (allowed for personal use)
>
> Bulk API not available but HTML parsing works
>
> import requests
>
> from bs4 import BeautifulSoup import pandas as pd
>
> def scrape_screener_financials(symbol): """Scrape financials from
> Screener.in"""
>
> url = f"https://www.screener.in/company/{symbol}/consolidated/"
>
> response = requests.get(url)
>
> \# Extract financial tables
>
> tables = pd.read_html(response.text)
>
> \# Parse balance sheet, P&amp;L, cash flow financials = {
>
> 'balance_sheet': tables\[0\], 'pl_statement': tables\[1\],
> 'cash_flow': tables\[2\]
>
> }
>
> return financials

**Source** **4:** **Economic** **Times** **RSS** **(News)**

> **URL**:
>
> [<u>https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms</u>](https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms)
>
> [<u>https://www.moneycontrol.com/rss/marketreports.xml</u>](https://www.moneycontrol.com/rss/marketreports.xml)
>
> **Frequency**: Real-time news feed
>
> **Cost**: Free
>
> import feedparser
>
> def fetch_financial_news():
>
> """Fetch real-time financial news from RSS"""
>
> rss_feeds = \[
> 'https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms',
> 'https://www.moneycontrol.com/rss/marketreports.xml',
> 'https://www.reuters.com/finance'
>
> \]
>
> all_articles = \[\]
>
> for feed_url in rss_feeds:
>
> feed = feedparser.parse(feed_url)
>
> for entry in feed.entries\[:20\]: \# Latest 20 article = {
>
> 'title': entry.title, 'link': entry.link,
>
> 'published': entry.published, 'summary': entry.summary, 'source':
> feed.feed.title
>
> } all_articles.append(article)
>
> return all_articles

**Source** **5:** **SEBI** **Filings** **(Regulatory)**

> **URL**:
> [<u>https://www.nseindia.com/companies-listing/corporate-filings-annual-reports</u>](https://www.nseindia.com/companies-listing/corporate-filings-annual-reports)
>
> **Contains**: Insider trading, shareholding, board meetings
>
> **Update** **Frequency**: Quarterly + event-driven
>
> **Format**: PDF, HTML

**Source** **6:** **Company** **IR** **Pages** **(Direct** **Download)**

Each NIFTY 50 company maintains investor relations pages with direct PDF
links:

> Reliance:
> [<u>https://www.ril.com/investors</u>](https://www.ril.com/investors)
>
> HDFC Bank:
> [<u>https://www.hdfcbank.com/investors</u>](https://www.hdfcbank.com/investors)
>
> TCS:
> [<u>https://www.tcs.com/investor</u>](https://www.tcs.com/investor)
>
> etc.
>
> \# Example: Automated annual report download from company IR pages
> ir_pages = {
>
> 'RELIANCE.NS': 'https://www.ril.com/investors/annual-reports',
> 'HDFCBANK.NS': 'https://www.hdfcbank.com/investors/annual-reports',
> 'TCS.NS': 'https://www.tcs.com/investor/reports-and-filings'
>
> }
>
> def download_annual_reports_from_ir(company_symbol, ir_url):
> """Download latest annual reports from company IR pages""" response =
> requests.get(ir_url)
>
> soup = BeautifulSoup(response.content, 'html.parser')
>
> \# Find PDF links (typically named like "annual-report-2024.pdf")
> pdf_links = soup.find_all('a', href=lambda x: x and '.pdf' in
> x.lower())
>
> for link in pdf_links:
>
> if 'annual' in link.text.lower(): pdf_url = link.get('href')
>
> \# Download and save
>
> pdf_response = requests.get(pdf_url)
>
> with open(f"annual_reports/{company_symbol}\_report.pdf", 'wb') as f:
> f.write(pdf_response.content)

**Earnings** **Transcripts**

**Primary** **Source:** **Company** **IR** **Pages** **&** **BSE**

> Typically available in PDF or HTML format
>
> Usually published 1-2 weeks after earnings call
>
> Not always automated, but can be fetched from:
>
> Company IR investor relations pages
>
> BSE corporate announcements
>
> Manual collection then ingestion
>
> def fetch_earnings_transcripts(): """
>
> Earnings transcripts are often on company IR pages or BSE Example for
> a few major companies with known locations """
>
> transcript_sources = {
>
> 'TCS': 'https://www.tcs.com/investor/financial-results',
>
> 'INFY': 'https://www.infosys.com/investors/reports-and-filings',
> 'RELIANCE': 'https://www.ril.com/investors/financial-results'
>
> }
>
> \# Transcripts often in PDF or webpage
>
> \# Manual download for MVP, then automate based on pattern

**Part** **2:** **Document** **Collection** **Strategy**

**2.1** **Initial** **Bootstrap** **Phase** **(Week** **1-2)**

**Objective**: Populate initial knowledge base with historical documents

**Step** **1:** **Prepare** **NIFTY** **50** **Company** **List**

> \# nifty_50_companies.csv symbol,company_name,sector,market_cap_rank
> RELIANCE.NS,Reliance Industries Ltd,Energy,1 HDFCBANK.NS,HDFC Bank
> Ltd,Banking,2 ICICIBANK.NS,ICICI Bank Ltd,Banking,3 TCS.NS,Tata
> Consultancy Services,IT,4 INFY.NS,Infosys Ltd,IT,5
>
> \# ... and 45 more

**Step** **2:** **Batch** **Download** **Annual** **Reports**

> import os import requests
>
> from bs4 import BeautifulSoup import time
>
> class AnnualReportDownloader:
>
> """Download annual reports for all NIFTY 50 companies"""
>
> def \_\_init\_\_(self, output_dir='annual_reports'): self.output_dir =
> output_dir os.makedirs(output_dir, exist_ok=True) self.nse_base_url =
> "https://www.nseindia.com"
>
> def download_for_all_companies(self, symbols, years=\['2024', '2023',
> '2022'\]): """
>
> Download annual reports from NSE for multiple companies """
>
> for symbol in symbols:
>
> print(f"Fetching reports for {symbol}...")
>
> for year in years:
>
> \# Construct NSE URL (pattern-based)
>
> url =
> f"{self.nse_base_url}/companies-listing/corporate-filings-annual-re
>
> try:
>
> \# Fetch the page
>
> response = requests.get(url, timeout=10)
>
> soup = BeautifulSoup(response.content, 'html.parser')
>
> \# Find PDF links for the specific year
>
> pdf_links = soup.find_all('a', href=lambda x: x and '.pdf' in x.lower
>
> for link in pdf_links:
>
> pdf_url = link.get('href')
>
> if not pdf_url.startswith('http'): pdf_url = self.nse_base_url +
> pdf_url
>
> \# Download
>
> self.\_download_pdf(pdf_url, symbol, year)
>
> except Exception as e:
>
> print(f"Error fetching {symbol} {year}: {e}")
>
> time.sleep(2) \# Rate limiting
>
> def \_download_pdf(self, url, symbol, year): """Download and save
> PDF"""
>
> try:
>
> response = requests.get(url, timeout=30)
>
> filename = f"{self.output_dir}/{symbol}\_annual_report\_{year}.pdf"
>
> with open(filename, 'wb') as f: f.write(response.content)
>
> print(f"Downloaded: {filename}") except Exception as e:
>
> print(f"Failed to download from {url}: {e}")
>
> \# Usage
>
> downloader = AnnualReportDownloader()
>
> nifty_50_symbols = \['RELIANCE.NS', 'HDFCBANK.NS', 'ICICIBANK.NS',
> ...\] \# 50 symbols
> downloader.download_for_all_companies(nifty_50_symbols,
> years=\['2024', '2023', '2022'\])

**Step** **3:** **Scrape** [<u>Screener.in</u>](http://screener.in/)
**Financial** **Data**

> import pandas as pd import requests
>
> from bs4 import BeautifulSoup import json
>
> import time
>
> class ScreenerDataCollector:
>
> """Collect historical financial data from Screener.in"""
>
> def \_\_init\_\_(self, output_dir='financial_data'): self.output_dir =
> output_dir os.makedirs(output_dir, exist_ok=True) self.base_url =
> "https://www.screener.in"
>
> def collect_for_all_companies(self, symbols): """Collect financial
> data for all companies"""
>
> all_data = {}
>
> for symbol in symbols:
>
> print(f"Collecting data for {symbol}...")
>
> try:
>
> \# Balance Sheet
>
> bs = self.\_fetch_balance_sheet(symbol)
>
> \# P&amp;L Statement
>
> pl = self.\_fetch_pl_statement(symbol)
>
> \# Cash Flow
>
> cf = self.\_fetch_cash_flow(symbol)
>
> all_data\[symbol\] = { 'balance_sheet': bs, 'pl_statement': pl,
> 'cash_flow': cf
>
> }
>
> \# Save to JSON
>
> with open(f"{self.output_dir}/{symbol}\_financials.json", 'w') as f:
> json.dump(all_data\[symbol\], f, indent=2)
>
> except Exception as e:
>
> print(f"Error collecting data for {symbol}: {e}")
>
> time.sleep(1) \# Rate limiting
>
> return all_data
>
> def \_fetch_balance_sheet(self, symbol): """Fetch balance sheet from
> Screener.in"""
>
> url = f"{self.base_url}/company/{symbol}/consolidated/"
>
> try:
>
> \# Read HTML tables
>
> tables = pd.read_html(url)
>
> \# Balance sheet is typically in a specific table bs_data =
> tables\[0\].to_dict('records')
>
> return bs_data except Exception as e:
>
> print(f"Error fetching balance sheet for {symbol}: {e}") return None
>
> def \_fetch_pl_statement(self, symbol): """Fetch P&amp;L statement"""
>
> \# Similar structure to balance sheet pass
>
> def \_fetch_cash_flow(self, symbol): """Fetch cash flow statement"""
> \# Similar structure
>
> pass

\# Usage

collector = ScreenerDataCollector()

nifty_50_symbols = \['RELIANCE.NS', 'HDFCBANK.NS', ...\]
collector.collect_for_all_companies(nifty_50_symbols)

**Step** **4:** **Download** **Quarterly** **Results** **(Last** **8**
**Quarters)**

> import requests
>
> from datetime import datetime, timedelta
>
> class QuarterlyResultsDownloader:
>
> """Download quarterly results from NSE"""
>
> def \_\_init\_\_(self, output_dir='quarterly_results'):
> self.output_dir = output_dir os.makedirs(output_dir, exist_ok=True)
>
> def get_last_8_quarters(self):
>
> """Get dates for last 8 quarters""" quarters = \[\]
>
> today = datetime.now()
>
> for i in range(8):
>
> quarter = ((today.month - 1) // 3) - i
>
> year = today.year - (1 if quarter &lt; 0 else 0) quarter = quarter % 4
>
> quarters.append((year, quarter + 1))
>
> return sorted(quarters)
>
> def download_quarterly_results(self, symbols): """Download Q3, Q4,
> etc. results"""
>
> quarters = self.get_last_8_quarters()
>
> for symbol in symbols:
>
> print(f"Downloading quarterly results for {symbol}...")
>
> for year, q in quarters:
>
> \# NSE URL pattern for announcements
>
> url =
> f"https://www.nseindia.com/market-data/announcement?symbol={symbol}
>
> try:
>
> response = requests.get(url, timeout=10)
>
> \# Parse and find Q3 results announcement links
>
> soup = BeautifulSoup(response.content, 'html.parser')
>
> \# Extract PDF links
>
> pdf_links = soup.find_all('a', href=lambda x: x and 'q' in x.lower()
>
> for link in pdf_links:
>
> pdf_url = link.get('href') self.\_download_pdf(pdf_url,
> f"{symbol}\_Q{q}\_{year}")
>
> except Exception as e:
>
> print(f"Error for {symbol} Q{q} {year}: {e}")
>
> time.sleep(1)

**2.2** **Real-Time** **Collection** **Phase** **(Ongoing)**

**Objective**: Continuously ingest new documents as they're released

**Real-Time** **News** **Ingestion**

> import feedparser import time
>
> from datetime import datetime import json
>
> class RealTimeNewsCollector:
>
> """Collect and ingest news in real-time"""
>
> def \_\_init\_\_(self, nifty_symbols, output_dir='news_data'):
> self.nifty_symbols = nifty_symbols
>
> self.output_dir = output_dir os.makedirs(output_dir, exist_ok=True)
>
> self.rss_feeds = \[
> 'https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms',
> 'https://www.moneycontrol.com/rss/marketreports.xml',
> 'https://feeds.bloomberg.com/markets/news.rss'
>
> \]
>
> self.last_processed = {} \# Track last processed article per symbol
>
> def run_continuous_collection(self, poll_interval_seconds=300): """
>
> Run continuous news collection Poll every 5 minutes by default """
>
> while True:
>
> print(f"\[{datetime.now()}\] Polling news feeds...")
>
> articles = self.\_fetch_all_feeds()
>
> \# Filter articles relevant to NIFTY 50 companies relevant_articles =
> self.\_filter_for_nifty_50(articles)
>
> \# Save and index
>
> for article in relevant_articles:
> self.\_save_and_index_article(article)
>
> \# Wait for next poll time.sleep(poll_interval_seconds)
>
> def \_fetch_all_feeds(self): """Fetch from all RSS feeds"""
> all_articles = \[\]
>
> for feed_url in self.rss_feeds: try:
>
> feed = feedparser.parse(feed_url)
>
> for entry in feed.entries\[:50\]: \# Latest 50 per feed article = {
>
> 'title': entry.get('title', ''), 'link': entry.get('link', ''),
>
> 'published': entry.get('published', ''), 'summary':
> entry.get('summary', ''), 'source': feed.feed.get('title', 'Unknown'),
> 'fetch_time': datetime.now().isoformat()
>
> } all_articles.append(article)
>
> except Exception as e:
>
> print(f"Error fetching {feed_url}: {e}")
>
> return all_articles
>
> def \_filter_for_nifty_50(self, articles):
>
> """Filter articles mentioning NIFTY 50 companies""" relevant = \[\]
>
> company_keywords = {
>
> 'RELIANCE.NS': \['Reliance', 'RIL', 'Mukesh Ambani'\], 'HDFCBANK.NS':
> \['HDFC Bank', 'HDFC'\], 'ICICIBANK.NS': \['ICICI Bank'\],
>
> 'TCS.NS': \['Tata Consultancy', 'TCS'\], 'INFY.NS': \['Infosys'\],
>
> \# ... more keywords }
>
> for article in articles:
>
> content = (article\['title'\] + ' ' + article\['summary'\]).lower()
>
> for symbol, keywords in company_keywords.items():
>
> if any(kw.lower() in content for kw in keywords):
> article\['company_symbol'\] = symbol relevant.append(article)
>
> break
>
> return relevant
>
> def \_save_and_index_article(self, article): """Save article and queue
> for ingestion"""
>
> \# Save to JSON
>
> filename =
> f"{self.output_dir}/{article\['company_symbol'\]}\_{int(time.time())}.jso
>
> with open(filename, 'w') as f: json.dump(article, f, indent=2)
>
> print(f"Saved: {article\['title'\]\[:50\]}...")
>
> \# Queue for vector DB ingestion (will be done by ingestion pipeline)
> \# Can use Celery or simple file watcher

\# Usage

> collector = RealTimeNewsCollector(nifty_50_symbols)
> collector.run_continuous_collection(poll_interval_seconds=300) \#
> Every 5 minutes

**Real-Time** **Earnings** **Calendar** **Monitoring**

> from apscheduler.schedulers.background import BackgroundScheduler from
> apscheduler.triggers.cron import CronTrigger
>
> import requests
>
> class EarningsCalendarMonitor:
>
> """Monitor and fetch earnings call transcripts"""
>
> def \_\_init\_\_(self, nifty_symbols): self.nifty_symbols =
> nifty_symbols self.scheduler = BackgroundScheduler()
>
> def start_monitoring(self):
>
> """Start background scheduler for earnings events"""
>
> \# Check earnings calendar daily at 9 AM IST self.scheduler.add_job(
>
> self.check_earnings_today, trigger=CronTrigger(hour=9, minute=0),
> id='daily_earnings_check'
>
> )
>
> self.scheduler.start()
>
> def check_earnings_today(self):
>
> """Check if any NIFTY 50 company has earnings today"""
>
> \# Use financial calendar API or manual list earnings_today =
> self.\_get_earnings_calendar_today()
>
> for company in earnings_today:
>
> if company\['symbol'\] in self.nifty_symbols: print(f"Earnings today
> for {company\['company'\]}")
>
> \# Schedule transcript fetch for evening (usually 8 PM after call)
> self.scheduler.add_job(
>
> self.fetch_earnings_transcript, 'date',
>
> run_date=datetime.now().replace(hour=20, minute=0),
> args=\[company\['symbol'\]\]
>
> )
>
> def fetch_earnings_transcript(self, symbol): """Fetch earnings
> transcript after call"""
>
> \# Try multiple sources: company IR, BSE, Moneycontrol
>
> sources = \[
>
> f"https://www.nseindia.com/market-data/company-announcements?symbol={symbol}"
> f"https://www.bseindia.com/announcements/{symbol}",
>
> \]
>
> for source in sources: try:
>
> response = requests.get(source)
>
> soup = BeautifulSoup(response.content, 'html.parser')
>
> \# Look for earnings transcript PDF
>
> pdf_links = soup.find_all('a', href=lambda x: x and 'transcript' in
> x.low
>
> if pdf_links:
>
> for link in pdf_links:
>
> pdf_url = link.get('href') self.\_download_transcript(pdf_url, symbol)
>
> except Exception as e:
>
> print(f"Error fetching transcript for {symbol}: {e}")

**Part** **3:** **Document** **Processing** **Pipeline**

**3.1** **Automated** **Ingestion** **Flow**

> from llama_index.core import VectorStoreIndex, StorageContext,
> ServiceContext, Document from llama_index.vector_stores.qdrant import
> QdrantVectorStore
>
> from llama_index.core.node_parser import ( HierarchicalNodeParser,
> SemanticSplitterNodeParser, SentenceSplitter
>
> )
>
> from llama_index.embeddings.openai import OpenAIEmbedding from
> llama_index.llms.openai import OpenAI
>
> from qdrant_client import QdrantClient import os
>
> import hashlib
>
> class DocumentIngestionPipeline: """
>
> Complete LlamaIndex-based ingestion pipeline
>
> Handles parsing, chunking, deduplication, and vector DB insertion """
>
> def \_\_init\_\_(self):
>
> \# Initialize LlamaIndex
>
> self.llm = OpenAI(model="gpt-4o", temperature=0)
>
> self.embed_model = OpenAIEmbedding(model="text-embedding-3-large")
>
> self.service_context = ServiceContext.from_defaults( llm=self.llm,
>
> embed_model=self.embed_model )
>
> \# Initialize Qdrant self.qdrant_client = QdrantClient(
>
> host="localhost", port=6333
>
> )
>
> self.vector_store = QdrantVectorStore( client=self.qdrant_client,
> collection_name="nifty_50_financial_kb"
>
> )
>
> self.storage_context = StorageContext.from_defaults(
> vector_store=self.vector_store
>
> )
>
> \# Initialize index
>
> self.index = VectorStoreIndex( \[\],
>
> storage_context=self.storage_context,
> service_context=self.service_context
>
> )
>
> \# Document parsers per type self.parsers = {
>
> 'annual_report':
> HierarchicalNodeParser.from_defaults(chunk_sizes=\[2048, 512\]
> 'earnings_transcript':
> SemanticSplitterNodeParser.from_defaults(breakpoint_pe
> 'quarterly_result':
> HierarchicalNodeParser.from_defaults(chunk_sizes=\[1024, 2
> 'news_article': SentenceSplitter(chunk_size=512, chunk_overlap=50),
> 'financial_statement': SentenceSplitter(chunk_size=1024,
> chunk_overlap=100)
>
> }
>
> def ingest_document(self, file_path, doc_type, company_symbol): """
>
> Main ingestion method
>
> Args:
>
> file_path: Path to document (PDF, HTML, or txt)
>
> doc_type: Type of document (annual_report, news_article, etc.)
> company_symbol: NIFTY 50 symbol (e.g., 'RELIANCE.NS')
>
> """
>
> print(f"Ingesting {doc_type} for {company_symbol}...")
>
> \# Step 1: Load document
>
> documents = self.\_load_document(file_path)
>
> \# Step 2: Enrich with metadata for doc in documents:
>
> doc.metadata.update({ 'company_symbol': company_symbol,
> 'document_type': doc_type,
>
> 'source_file': os.path.basename(file_path), 'ingestion_timestamp':
> datetime.now().isoformat()
>
> })
>
> \# Step 3: Parse with appropriate strategy
>
> parser = self.parsers.get(doc_type, self.parsers\['news_article'\])
> nodes = parser.get_nodes_from_documents(documents)
>
> \# Step 4: Deduplicate
>
> unique_nodes = self.\_deduplicate_nodes(nodes)
>
> \# Step 5: Insert into vector DB self.index.insert_nodes(unique_nodes)
>
> print(f"Successfully ingested {len(unique_nodes)} nodes")
>
> return len(unique_nodes)
>
> def \_load_document(self, file_path): """Load document based on file
> type"""
>
> if file_path.endswith('.pdf'):
>
> from llama_index.readers.file import PDFReader reader = PDFReader()
>
> return reader.load_data(file_path)
>
> elif file_path.endswith('.html'):
>
> from llama_index.readers.web import BeautifulSoupWebReader reader =
> BeautifulSoupWebReader()
>
> return reader.load_data(\[file_path\])
>
> elif file_path.endswith('.txt'): with open(file_path, 'r') as f:
>
> content = f.read()
>
> return \[Document(text=content)\]
>
> else:
>
> raise ValueError(f"Unsupported file type: {file_path}")
>
> def \_deduplicate_nodes(self, nodes):
>
> """Prevent duplicate ingestion using content hashing"""
>
> unique_nodes = \[\] seen_hashes = set()
>
> for node in nodes:
>
> content_hash = hashlib.sha256( node.get_content().encode()
>
> ).hexdigest()
>
> if content_hash not in seen_hashes: node.metadata\['content_hash'\] =
> content_hash unique_nodes.append(node) seen_hashes.add(content_hash)
>
> return unique_nodes
>
> def batch_ingest_directory(self, directory, doc_type, company_symbol):
> """Ingest all documents from a directory"""
>
> total_nodes = 0
>
> for filename in os.listdir(directory): if filename.startswith('.'):
>
> continue
>
> file_path = os.path.join(directory, filename)
>
> if os.path.isfile(file_path): try:
>
> nodes_added = self.ingest_document( file_path,
>
> doc_type, company_symbol
>
> )
>
> total_nodes += nodes_added except Exception as e:
>
> print(f"Error ingesting {filename}: {e}")
>
> print(f"Total nodes ingested from {directory}: {total_nodes}") return
> total_nodes
>
> \# Usage
>
> pipeline = DocumentIngestionPipeline()
>
> \# Ingest annual reports pipeline.batch_ingest_directory(
>
> 'annual_reports/', 'annual_report', 'RELIANCE.NS'
>
> )
>
> \# Ingest news pipeline.batch_ingest_directory(
>
> 'news_data/', 'news_article', 'RELIANCE.NS'
>
> )

**Part** **4:** **Complete** **Data** **Collection** **Workflow**

**4.1** **Week-by-Week** **Implementation** **Plan**

**Week** **1:** **Bootstrap** **Historical** **Data**

**Days** **1-2:** **Setup** **&** **Preparation**

> \[ \] Create NIFTY 50 company list (CSV with symbol, name, sector)
>
> \[ \] Set up data directories (annual_reports/, quarterly_results/,
> news_data/, etc.)
>
> \[ \] Configure API keys (Upstox, Finnhub, OpenAI)
>
> \[ \] Initialize local Qdrant and PostgreSQL

**Days** **3-5:** **Annual** **Reports** **Download**

> \[ \] Run AnnualReportDownloader for last 3 years
>
> \[ \] Target: 150 PDFs (50 companies × 3 years)
>
> \[ \] Expected: 200-400 MB total

**Days** **6-7:** **Financial** **Statements** **&** **Fundamentals**

> \[ \] Run ScreenerDataCollector for all 50 companies
>
> \[ \] Collect last 10 years of fundamentals
>
> \[ \] Download EOD prices from yfinance (2 years)

**Week** **2:** **Quarterly** **Data** **&** **Initial** **Ingestion**

**Days** **1-2:** **Quarterly** **Results**

> \[ \] Download last 8 quarters of results
>
> \[ \] Target: 400 documents (50 × 8)

**Days** **3-4:** **News** **Backlog**

> \[ \] Collect last 30 days of news using Economic Times + Moneycontrol
> RSS
>
> \[ \] Extract mentions of NIFTY 50 companies
>
> \[ \] Save 1000+ articles

**Days** **5-7:** **Initial** **Ingestion**

> \[ \] Initialize DocumentIngestionPipeline
>
> \[ \] Ingest all annual reports
>
> \[ \] Ingest quarterly results
>
> \[ \] Ingest news articles (sample 100)

**Week** **3:** **Real-Time** **Setup** **&** **Testing**

**Days** **1-3:** **Real-Time** **News** **Collection**

> \[ \] Deploy RealTimeNewsCollector
>
> \[ \] Test on 1 company
>
> \[ \] Verify ingestion working

**Days** **4-5:** **Earnings** **Monitoring**

> \[ \] Set up EarningsCalendarMonitor
>
> \[ \] Configure scheduler for daily checks

**Days** **6-7:** **Testing** **&** **Optimization**

> \[ \] Test queries on ingested data
>
> \[ \] Optimize chunking strategies
>
> \[ \] Verify deduplication working

**Week** **4:** **Scaling** **&** **Production**

**Days** **1-3:** **Scale** **Real-Time** **Collection**

> \[ \] Enable news collection for all 50 companies
>
> \[ \] Scale to all data types

**Days** **4-5:** **Performance** **Optimization**

> \[ \] Add caching (Redis)
>
> \[ \] Optimize vector retrieval
>
> \[ \] Load test with realistic queries

**Days** **6-7:** **Monitoring** **&** **Documentation**

> \[ \] Set up logging
>
> \[ \] Document data collection procedures
>
> \[ \] Create runbooks

**Part** **5:** **Data** **Storage** **Architecture**

**5.1** **Storage** **Layers**

**Layer** **1:** **Vector** **Database** **(Qdrant)**

> **Purpose**: Full-text semantic search
>
> **Collections**:
>
> nifty_50_financial_kb - All documents
>
> Can partition by company or document type if needed

**Layer** **2:** **SQL** **Database** **(PostgreSQL)**

> **Tables**:
>
> companies - NIFTY 50 metadata
>
> fundamentals - Financial metrics (quarterly/annual)
>
> prices - EOD price data
>
> documents - Document metadata & ingestion tracking
>
> ingestion_logs - Track what's been ingested
>
> -- Schema example
>
> CREATE TABLE companies ( id SERIAL PRIMARY KEY,
>
> symbol VARCHAR(20) UNIQUE, name VARCHAR(100),
>
> sector VARCHAR(50),
>
> market_cap_rank INT );
>
> CREATE TABLE fundamentals ( id SERIAL PRIMARY KEY,
>
> company_id INT REFERENCES companies(id), period VARCHAR(20), --
> Q1FY24, etc. revenue BIGINT,
>
> net_income BIGINT, eps FLOAT, pe_ratio FLOAT, roe FLOAT,
>
> created_at TIMESTAMP DEFAULT NOW() );
>
> CREATE TABLE documents ( id SERIAL PRIMARY KEY,
>
> company_id INT REFERENCES companies(id),
>
> doc_type VARCHAR(50), -- annual_report, news, etc. source_path
> VARCHAR(255),
>
> ingestion_timestamp TIMESTAMP, content_hash VARCHAR(64) UNIQUE,
>
> status VARCHAR(20) -- ingested, failed, pending );

**Layer** **3:** **Cache** **Layer** **(Redis)**

> **Purpose**: Cache LLM responses, embeddings
>
> **TTL**: 24 hours for queries, 7 days for historical

**Part** **6:** **Complete** **Implementation** **Checklist**

**Bootstrap** **Phase** **(Week** **1-2)**

> \[ \] NIFTY 50 company list created (CSV)
>
> \[ \] All data directories created
>
> \[ \] Qdrant instance running locally
>
> \[ \] PostgreSQL with schema created
>
> \[ \] API keys configured and tested

**Data** **Collected:**

> \[ \] Annual reports: 50 × 3 years = 150 PDFs
>
> \[ \] Quarterly results: 50 × 8 = 400 PDFs
>
> \[ \] Fundamentals: 50 × 10 years = historical data
>
> \[ \] News articles: ~1000 from past 30 days

**Real-Time** **Phase** **(Week** **3-4)**

> \[ \] News collection running (every 5 min)
>
> \[ \] Earnings calendar monitoring active
>
> \[ \] Ingestion pipeline operational
>
> \[ \] Vector DB populated with 5,000+ nodes
>
> \[ \] SQL database updated daily

**Production** **Phase** **(Week** **5+)**

> \[ \] Kubernetes deployment ready
>
> \[ \] Monitoring & alerting configured
>
> \[ \] Backup & recovery procedures
>
> \[ \] Performance optimized

**Part** **7:** **Quick** **Reference** **-** **Command** **Cheatsheet**

> \# Download annual reports
>
> python download_annual_reports.py --symbols RELIANCE.NS,HDFCBANK.NS
> --years 2024,2023
>
> \# Collect quarterly data
>
> python collect_quarterly_results.py --symbols all_nifty_50.csv
>
> \# Start real-time news collection
>
> python start_news_collection.py --poll-interval 300
>
> \# Ingest documents
>
> python ingest_documents.py --directory annual_reports/ --doc-type
> annual_report
>
> \# Query the system
>
> python query_rag.py "What was Reliance's revenue in FY2024?"
>
> \# Check ingestion status
>
> python check_ingestion_status.py --company RELIANCE.NS

**Summary:** **Data** **Collection** **Overview**

||
||
||
||
||
||

**Total** **Implementation** **Time**: 4 weeks **Estimated** **Data**
**Size**: 1-2 GB

**Document** **Count**: 5,000-10,000 **Vector** **DB** **Size**:
50,000-100,000 nodes **Companies** **Covered**: 50 (NIFTY 50)

**Data** **Freshness**: Real-time news, daily prices, quarterly
fundamentals

**Next** **Steps**

> 1\. **Week** **1**: Execute bootstrap phase from this document
>
> 2\. **Week** **2-3**: Deploy real-time collection
>
> 3\. **Week** **4**: Deploy to production with monitoring
>
> 4\. **Week** **5+**: Scale and iterate based on usage

You now have a **complete** **data** **collection** **strategy** for
your NIFTY 50 financial analysis RAG MVP!
