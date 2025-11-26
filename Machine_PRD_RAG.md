**Agentic** **NIFTY** **50** **Financial** **RAG** **System**
**Machine-Readable** **Technical** **Requirements** **Document**

**1.** **System** **Universe**

> ● Subject Universe: All companies in the NIFTY 50
>
> ● index, covering all industrial sectors represented within, as of the
> latest index composition.
>
> ● Temporal Coverage: All document types for the past 3 years, plus
> real-time collection of new documents or data daily.

**2.** **Data** **Inputs** **(Ingestion** **Requirements)**

> ● 2.1 Annual Reports
>
> ● Must ingest PDFs of full annual reports for each NIFTY 50 company
> for the last 3 years.
>
> ● Each annual report PDF is parsed to preserve table structure as HTML
> or Markdown.
>
> ● Each report is chunked both hierarchically (by heading/section) and
> semantically (by topic shift).
>
> ● All tables are stored as separate searchable units attached to their
> originating sections.
>
> ● 2.2 Quarterly Results
>
> ● Must ingest quarterly financial result PDFs for the most recent 8
> quarters (~2 years).
>
> ● Each result is parsed for table structure, entity names, financial
> values, and time periods.
>
> ● 2.3 Price and Fundamentals Data
>
> ● Must ingest daily OHLCV trading data (Open, High, Low, Close,
> Volume) for 3 years.
>
> ● Must ingest and store quarterly and annual structured financial
> fundamentals for each company (Revenue, Net Profit, EPS, PE,
> Debt/Equity, Book Value, ROE, Market Cap, Sector).
>
> ● 2.4 News Articles
>
> ● Must collect and ingest headlines, summaries, bodies, and publish
> dates of news referencing NIFTY 50 companies, from approved RSS/XML
> feeds (Economic Times, Moneycontrol, etc.) for rolling last 30 days.
>
> ● Sentiment, named-entity, and section/topic tags must be parsed per
> article.
>
> ● 2.5 Regulatory Corporate Filings
>
> ● Must monitor and collect real-time event-based filings via
> NSE/BSE/SEBI portals for filings relevant to NIFTY 50 companies.
>
> ● 2.6 Earnings Call Transcripts (Optional for MVP)
>
> ● If available, must parse and store last 4 transcripts per company,
> preserving Q&A, management remarks, and timestamps.

**3.** **Document** **Processing** **Rules**

> ● 3.1 Table and Section Extraction
>
> ● Every PDF or HTML financial document must be parsed (typically via
> LlamaParse or similar vision-Language parser) with all tables
> represented as HTML/Markdown and all headings/subsections retained in
> metadata.
>
> ● 3.2 Chunking Strategy
>
> ● Must create at least two sets of chunks for every document:
> hierarchical (sections/subsections) and semantic (topic boundary by
> embeddings).
>
> ● Parent–child document relationships (chunk–section, table–section,
> etc.) must be preserved.
>
> ● 3.3 Metadata Enrichment
>
> ● All chunks/tables must be tagged with company symbol, fiscal period,
> document type, section, and ingestion timestamp.
>
> ● All parsed entities (e.g., company officers, financial ratios) must
> be normalized with name and role labels.

**4.** **Retrieval-Augmented** **Generation** **Pipeline**
**Requirements**

> ● 4.1 Hybrid Search
>
> ● Must implement dense vector/similarity search (Qdrant or equivalent)
> and BM25 keyword retrieval.
>
> ● Must be able to query both at once and merge results.
>
> ● For fuzzy queries, pipeline must attempt HyDE (LLM-hallucinated
> answer) embedding retrieval.
>
> ● 4.2 Parent–Child/Multivector Strategy
>
> ● All retrieved "child" chunks point to a "parent" section or
> document; answer context must be expanded as needed.
>
> ● Table "children" retrieved must be supported with narrative or
> row-level summaries for LLM prompt use.
>
> ● 4.3 RAG Agent Workflow
>
> ● Inputs: User natural language query, plus optional time/company
> filter ● Stages:
>
> 1\. Query Analysis Agent: Determines intent, query type, filter
> parameters, and if extractions/tools are required.
>
> 2\. Retriever Agent: Executes hybrid, multivector (summary/table)
> search.
>
> 3\. Filter Agent: Prunes results by date, relevance; can escalate to
> web search or knowledge graph agent if needed.
>
> 4\. Synthesis Agent: Constructs in-prompt context, including tables as
> markdown/HTML, with narrations and citations.
>
> 5\. Fact Checker: Runs LLM-based audit (“Is generated answer
> consistent with provided context, or hallucinated?”). Loops back if
> fail.
>
> 6\. Citation and Output Agent: Finalizes answer with references to all
> sources/documents/chunks/tables used.
>
> 7\. (Optional) HITL Agent: Pauses flow for human review for flagged,
> ambiguous, or high-compliance queries.
>
> ● All agent actions, inputs, and results are step-logged (see
> Monitoring/Observability).

**5.** **Knowledge** **Graph** **(KG)** **Requirements**

> ● KG Entity Extraction:
>
> ● Agents must extract relationships from filings (ownership, board,
> auditor, suppliers, competitors) and store in a knowledge graph (Neo4j
> or equivalent).
>
> ● KG must support multi-hop queries (e.g., “Who are the ultimate
> promoters of Company X?”).
>
> ● Text2Cypher Reasoning:
>
> ● LLM must translate natural language relational queries into Cypher
> statements run against the KG.
>
> ● For answers requiring KG, the pipeline routes to KG agent first,
> then combines results with document retrieval.

**6.** **Monitoring,** **Safety** **&** **Compliance**

> ● 6.1 Observability
>
> ● All agent workflow steps must be logged (LangSmith or similar), with
> links to input queries, outputs, and intermediate decisions.
>
> ● Checkpoints must be serializable; system state can be resumed after
> interruption at any step.
>
> ● 6.2 Guardrails
>
> ● All inputs and outputs must pass PII/Compliance scanning (can use
> NeMo/Colang or regex at MVP).
>
> ● System must support settable block/pass/rewrite rules for
> banned/restricted topics.
>
> ● 6.3 Human-in-the-Loop (HITL)
>
> ● Any answer above a risk/confidence threshold, as well as flagged
> queries (complex, compliance, ambiguous), must pause agent workflow,
> serialize all context, and await explicit human approval or
> intervention.

**7.** **Frontend,** **Backend,** **and** **Infrastructure**

> ● Frontend: Next.js (React, Typescript) webapp includes: company
> search/selection, financial dashboards, news feed, query/answer UI,
> download links, and comparison tools.
>
> ● Backend: FastAPI (Python) provides all application APIs (REST,
> Swagger/OpenAPI docs, JWT/CORS support).
>
> ● Vector DB: Qdrant deployed, all embeddings and vectors resident
> here.
>
> ● SQL/Timescale: PostgreSQL/TimescaleDB holds structured, timeseries,
> and analytics data.
>
> ● Redis: Used for caching and Celery job broker.
>
> ● File/Object Storage: GCP Cloud Storage bucket for PDFs, backups, and
> large assets.
>
> ● Deployment: All core infra on GCP Compute Engine VM (with
> docker-compose; each service as container), using Cloud Storage and
> (optional) Cloud SQL.

**8.** **Success** **Metrics**

> ● Answers must cover at least 90% of real/expected NIFTY 50 investor
> queries, with citation trace for every fact/table.
>
> ● System must ingest all major document types for all companies,
> keeping in sync within a rolling 24h window.
>
> ● RAG retrieval recall: \>90% on goldset financial/narrative QA pairs.
> ● Hallucination rate: \<2% on sampled system output.
>
> ● End-to-end agentic workflow traceability for all questions.

*Each* *requirement* *above* *must* *be* *implemented* *either* *as* *a*
*direct* *step* *in* *the* *system’s* *software* *workflow* *or* *as*
*a* *modular* *component* *agent,* *ready* *to* *be* *called,*
*parameterized,* *or* *audited* *in* *the* *agentic* *pipeline.* *The*
*system* *should* *be* *able* *to* *“explain* *its* *work”* *by*
*outputting* *the* *data* *flow,* *agent* *flow,* *and* *provenance*
*of* *all* *answers.*
