**NIFTY** **50** **Financial** **Agentic** **RAG:** **Integrated**
**Project** **Plan** **&** **PRD**

**1.** **Coverage** **&** **Focus**

> ● **Universe:** NIFTY 50 (top 50, all sectors)
>
> ● **Period:** 3y historical + daily real-time updates (news, filings,
> prices) ● **Sectors:** All major NIFTY 50 segments

**2.** **Data** **Types**

> ● Annual Reports (PDFs, 3 years)
>
> ● Quarterly Results (PDFs, 8 quarters)
>
> ● Key Fundamentals (quarterly/annual, yfinance/Screener.in) ● Price
> Data (EOD OHLCV, 3 years)
>
> ● News Articles (real-time, 30d rolling)
>
> ● Corporate Filings (NSE/BSE/SEBI events)
>
> ● Earnings Call Transcripts (4 quarters, if available)

**3.** **System** **Features** **&** **Pipeline** **(with** **Overkill**
**Features** **Integrated)**

**A.** **Automated** **Ingestion** **&** **Scheduling**

> ● **Bulk** **bootstrap**: Initial pop of historic PDFs/documents.
>
> ● **Schedulers** **(Celery** **Beat/cron):** 5min–daily polling of
> news, filings, document releases. ● **Event-Based** **Triggers**:
> React to new filings in real-time.

**B.** **Advanced** **Parsing** **&** **Context** **Engineering**

> ● **LlamaParse** **(VQA/table)**: PDF → Markdown/HTML table output
> (supports output_tables_as_HTML for ultimate fidelity).
>
> ● **Enhanced** **Table/Narrative** **Hybridization**: Semantic
> summaries for search, raw tables retained for answer synthesis
> (parent-child vector approach).
>
> ● **Automatic** **Section** **Tagging**: Detects headings/metadata
> (MD&A, P&L, Governance, etc.) to route agents/tools by section.
>
> ● **Parent–Child** **Document** **Strategy**: Locally-relevant
> “children” for search; fallback/expand to “parent” for full answer
> context.

**C.** **Chunking/Representation** **Strategies**

> ● **HierarchicalNodeParser** **&** **SemanticSplitter**
> **(LlamaIndex)**:
>
> Multi-scale—whole-section down to fine-grained sentence or semantic
> chunk.
>
> ● **Multi-Granularity** **Retrieval**: All documents are chunked at
> \>1 scale, with both summary and granular vectors created.
>
> ● **Table/Entity** **Extraction:** Inline extraction and linking of
> named entities, key ratios, and table structures.

**D.** **Knowledge** **Graph** **/** **GraphRAG** **Capabilities**
**(Enterprise-Explicit)**

> ● **Entity** **Relation** **Extraction:** Extract board members,
> ownership, suppliers, competitors, large events, and turn into a Neo4j
> (or ArangoDB) KG.
>
> ● **Text2Cypher** **Agent:** LLM generates Cypher for
> multi-hop/relational queries (“Who owns X? Who are all suppliers Y?”)
>
> ● **Graph-Augmented** **Search/Reasoning:** For entity, multiple-hop,
> or subgraph queries, KG can contribute context directly to retriever.

**E.** **RAG** **Pipeline** **&** **Agentic** **Orchestration**

> ● **LangGraph** **DAG** **State** **Machine:** With the following
> agent “nodes”, all modular and swappable:
>
> ○ **Query** **/** **Intent** **Analyzer** (parses, routes)
>
> ○ **Retriever** **(Hybrid):** semantic vector, BM25, and KG search
>
> ○ **Document** **Filter:** pre-citation filter (relevance, date,
> confidence)
>
> ○ **LLM** **Answer** **Synthesizer:** RAG prompt assembly,
> table-to-markdown, reference in-prompt citations
>
> ○ **Fact** **Checker** **/** **Reflective** **Node:** Post-generation
> hallucination check, self-consistency, contradiction search
>
> ○ **Feedback/Retrieval** **Loop:** If answer fails grade, query is
> reformulated or alternative retrieval route (external web) used
>
> ○ **Citation** **and** **Explanation** **Node**: Ensures all claims
> are traced to docs/tables/graphs

**F.** **Multi-Agent** **Supervisor** **and** **Subagent**
**Specialization**

> ● All main roles above as explicit, parameterized agents (Research,
> Graph, Reviewer, Synthesizer, Table Calculator)
>
> ● **Supervisor** **Node:** Orchestrates/assigns, aggregates
> multi-agent outputs, resolves conflicts

**G.** **LLM** **Fast** **Inferencing**

> ● **Groq** **(primary),** **OpenAI,** **or** **fallback** **LLM**
> **endpoint.**
>
> ● Model selection/prompts based on query type, document type, doc
> size.

**H.** **Advanced** **Retrieval** **Features**

> ● **HyDE** **(Hypothetical** **Document** **Embeddings):** For
> fuzzy/complex investor queries, run LLM to generate “what would an
> answer be, hypothetically” → embed → retrieve→ synthesize with actual
> doc context for higher recall.
>
> ● **BM25** **fallback:** If semantic fails or query is highly
> “keywordy”.

**I.** **Observability,** **State,** **and** **Monitoring**

> ● **LangSmith** **full** **traceability:** All agent paths, nodes,
> tool calls, and fallback branches traced, log-accessible, and
> auditable
>
> ● **State** **Checkpointing:** Every agent node’s output/state
> serializable—enables time-travel/debug/HITL intervention
>
> ● **Automated** **RAGAS** **and** **Trajectory** **(“workflow”)**
> **Evaluation**: Golden QA, trace-level path tests, regular QA test
> suite

**J.** **Output** **Safety** **&** **Guardrails**

> ● **NeMo** **Guardrails/Colang/Middleware:** Step-level safety rails:
> Input/output filtering, compliance layer (PII detection, restricted
> topics, hallucination detection and blocking).
>
> ● **HITL** **(Human-in-the-Loop)** **Interrupt** **Capability:** For
> all high-stakes, ambiguous, or flagged queries; agent state can be
> paused, presented in UI for human review/override before final answer

**K.** **Frontend,** **API,** **and** **Deployment**

> ● **Frontend:** Next.js (Vercel or GCP hosted), Material-UI/Chakra for
> professional enterprise look; dashboard, compare, search, doc
> explorer, and Q&A flows
>
> ● **API** **Backend:** FastAPI (REST, documented, CORS-enabled for
> Next.js)
>
> ● **Redis:** Caching, Celery Broker, async background updates
>
> ● **Qdrant:** Vector DB (semantic search, parent/child separation)
>
> ● **PostgreSQL+Timescale:** Structured, timeseries, and analytic
> queries
>
> ● **GCP** **Compute** **Engine:** Docker Compose, static IP, daily
> backups, firewall, Secret Manager, monitoring/logs

**L.** **Optional** **/** **Advanced** **(Hooks** **Installed)**

> ● **Web** **Fallback** **Tool:** If retrieval fails, scrape/external
> search, inject into RAG (can use Tavily or SerpAPI as agent endpoint)
>
> ● **Bulk/Community** **Detection:** Routines for summarizing entity
> “graph neighborhoods”, themes clusters for sector-wide queries
>
> ● **API/Webhooks** **for** **extension:** Portfolio integration,
> alert/notification support (later version)

**4.** **EXCLUSIONS**

> ● No non-NIFTY companies
>
> ● No live trading or advice execution
>
> ● No deep individual user modeling (yet)
>
> ● No mass sectoral/entity graph for phase 1 (but all code and DB hooks
> present for v2)

**5.** **Success** **Criteria**

> ● Covers all queries (point/fuzzy/relational/comparative) about any
> NIFTY 50 metric or event, with full doc/tables/source traceability
>
> ● Ingestion covers \>90% of docs in 24h
>
> ● End-to-end trace/logs for every step, every agent, every tool ●
> Passed gold QA with \>90% correct, \<2% hallucination rate
>
> ● Deployed, monitored, and robust to errors, agent-state resumable
