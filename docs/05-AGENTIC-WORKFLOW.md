# 05 - Agentic Workflow (LangGraph)

## Overview

The agentic workflow uses LangGraph v1 to orchestrate a self-correcting RAG pipeline with:
- **Adaptive Routing** - Route queries to appropriate retrieval strategies
- **Document Grading** - Filter irrelevant documents
- **Query Rewriting** - Improve retrieval on failure
- **Fact Checking** - Detect and prevent hallucinations
- **Human-in-the-Loop** - Pause for human review when needed

---

## Workflow Diagram

```
                                    ┌─────────────┐
                                    │   START     │
                                    └──────┬──────┘
                                           │
                                           ▼
                                    ┌─────────────┐
                                    │   ROUTER    │
                                    │  (analyze   │
                                    │   query)    │
                                    └──────┬──────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
                    ▼                      ▼                      ▼
             ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
             │   DIRECT    │       │  RETRIEVE   │       │ WEB_SEARCH  │
             │   ANSWER    │       │  (hybrid)   │       │  (fallback) │
             └──────┬──────┘       └──────┬──────┘       └──────┬──────┘
                    │                     │                     │
                    │                     ▼                     │
                    │              ┌─────────────┐              │
                    │              │   GRADER    │              │
                    │              │ (relevance) │              │
                    │              └──────┬──────┘              │
                    │                     │                     │
                    │         ┌───────────┴───────────┐         │
                    │         │                       │         │
                    │         ▼                       ▼         │
                    │   ┌───────────┐          ┌───────────┐    │
                    │   │ RELEVANT  │          │  REWRITE  │────┤
                    │   │ (proceed) │          │  (retry)  │    │
                    │   └─────┬─────┘          └───────────┘    │
                    │         │                                 │
                    │         │◄────────────────────────────────┘
                    │         │
                    │         ▼
                    │  ┌─────────────┐
                    │  │  GENERATE   │
                    │  │  (answer)   │
                    │  └──────┬──────┘
                    │         │
                    │         ▼
                    │  ┌─────────────┐
                    │  │ FACT_CHECK  │
                    │  │(hallucinate)│
                    │  └──────┬──────┘
                    │         │
                    │    ┌────┴────┐
                    │    │         │
                    │    ▼         ▼
                    │ ┌──────┐ ┌──────────┐
                    │ │PASSED│ │REGENERATE│
                    │ └──┬───┘ └────┬─────┘
                    │    │          │
                    │    │◄─────────┘
                    │    │
                    │    ▼
                    │ ┌─────────────┐
                    │ │   CITE      │
                    │ │(references) │
                    │ └──────┬──────┘
                    │        │
                    └────────┼────────┐
                             │        │
                             ▼        │
                      ┌─────────────┐ │
                      │  HITL_CHECK │ │
                      │ (optional)  │ │
                      └──────┬──────┘ │
                             │        │
                    ┌────────┴────────┘
                    │
                    ▼
             ┌─────────────┐
             │     END     │
             └─────────────┘
```

---

## State Schema

```python
from typing import TypedDict, Annotated, Sequence, Optional, List, Literal
from langchain_core.messages import BaseMessage, HumanMessage, AIMessage
from langgraph.graph.message import add_messages
from pydantic import BaseModel, Field
from enum import Enum
from datetime import datetime

# ============= Enums =============

class QueryType(str, Enum):
    """Classification of query types"""
    FACTUAL = "factual"           # "What was TCS revenue in FY24?"
    COMPARATIVE = "comparative"    # "Compare HDFC and ICICI PE ratios"
    ANALYTICAL = "analytical"      # "Why did Reliance stock drop?"
    EXPLORATORY = "exploratory"    # "Tell me about Infosys"
    CURRENT_EVENTS = "current"     # "Latest news on Tata Motors"

class RouteDecision(str, Enum):
    """Routing decisions"""
    VECTOR_STORE = "vector_store"
    WEB_SEARCH = "web_search"
    DIRECT_ANSWER = "direct_answer"

class DocumentRelevance(str, Enum):
    """Document relevance grades"""
    RELEVANT = "relevant"
    IRRELEVANT = "irrelevant"

# ============= Structured Outputs =============

class QueryAnalysis(BaseModel):
    """Output of query analysis"""
    query_type: QueryType
    route: RouteDecision
    entities: List[str] = Field(default_factory=list, description="Company names mentioned")
    time_references: List[str] = Field(default_factory=list, description="Fiscal periods mentioned")
    requires_calculation: bool = Field(default=False, description="Needs numerical computation")
    reasoning: str = Field(description="Explanation of routing decision")

class DocumentGrade(BaseModel):
    """Output of document grading"""
    document_id: str
    relevance: DocumentRelevance
    relevance_score: float = Field(ge=0, le=1)
    key_information: str = Field(description="What useful info this doc contains")

class FactCheckResult(BaseModel):
    """Output of fact checking"""
    is_faithful: bool = Field(description="Is the answer grounded in sources?")
    confidence: float = Field(ge=0, le=1)
    unsupported_claims: List[str] = Field(default_factory=list)
    supported_claims: List[str] = Field(default_factory=list)
    reasoning: str

class Citation(BaseModel):
    """Citation for a claim"""
    claim: str
    document_id: str
    document_title: str
    source_text: str
    page_number: Optional[int] = None

# ============= Main State =============

class AgenticRAGState(TypedDict):
    """
    Main state for the agentic RAG workflow.
    
    This state is passed between all nodes and persisted
    for checkpointing and HITL.
    """
    
    # === Messages ===
    messages: Annotated[Sequence[BaseMessage], add_messages]
    
    # === Query ===
    original_query: str
    current_query: str  # May be rewritten
    query_analysis: Optional[QueryAnalysis]
    filters: Optional[dict]  # {company_symbol, fiscal_period, doc_types}
    
    # === Retrieval ===
    retrieved_documents: List[dict]  # Raw retrieval results
    document_grades: List[DocumentGrade]
    relevant_documents: List[dict]  # After grading
    
    # === Generation ===
    generated_response: Optional[str]
    fact_check_result: Optional[FactCheckResult]
    citations: List[Citation]
    
    # === Control Flow ===
    route_decision: Optional[RouteDecision]
    rewrite_count: int
    generation_attempt: int
    
    # === Limits ===
    max_rewrites: int  # Default: 2
    max_generations: int  # Default: 2
    
    # === HITL ===
    requires_human_review: bool
    hitl_reason: Optional[str]
    
    # === Metadata ===
    trace_id: Optional[str]
    user_id: Optional[int]
    started_at: Optional[str]
    
    # === Error Handling ===
    error: Optional[str]
```

---

## Node Implementations

### 1. Router Node

```python
from langchain_groq import ChatGroq
from langchain_core.prompts import ChatPromptTemplate

ROUTER_PROMPT = """You are a query router for a financial RAG system focused on NIFTY 50 companies.

Analyze the user's query and decide the best retrieval strategy:

1. **vector_store**: Use for questions about specific financial data, company performance,
   historical information that would be in annual reports, quarterly results, or filings.
   
2. **web_search**: Use for current events, recent news, or information that changes frequently
   and may not be in our document store.
   
3. **direct_answer**: Use for simple questions that don't require document retrieval,
   like "What is PE ratio?" or general financial concepts.

Also extract:
- Company names mentioned (use stock symbols like RELIANCE.NS, TCS.NS)
- Time periods mentioned (FY2024, Q3FY24, etc.)
- Whether calculation is needed

Query: {query}

Conversation history:
{history}

Analyze and respond with your routing decision."""

async def router_node(state: AgenticRAGState) -> dict:
    """
    Analyze query and decide routing strategy.
    
    Returns:
        Updated state with query_analysis and route_decision
    """
    
    llm = ChatGroq(model="llama-3.1-8b-instant", temperature=0)
    structured_llm = llm.with_structured_output(QueryAnalysis)
    
    # Build history string
    history = "\n".join([
        f"{msg.type}: {msg.content[:200]}"
        for msg in state["messages"][-5:]  # Last 5 messages
    ])
    
    # Get analysis
    analysis = await structured_llm.ainvoke(
        ROUTER_PROMPT.format(
            query=state["original_query"],
            history=history
        )
    )
    
    return {
        "query_analysis": analysis,
        "route_decision": analysis.route,
        "current_query": state["original_query"]
    }
```

### 2. Retrieve Node

```python
async def retrieve_node(state: AgenticRAGState) -> dict:
    """
    Execute hybrid retrieval.
    
    Returns:
        Updated state with retrieved_documents
    """
    
    # Build filters from query analysis
    filters = state.get("filters", {})
    
    if state["query_analysis"]:
        # Add company filter if mentioned
        if state["query_analysis"].entities:
            filters["company_symbol"] = state["query_analysis"].entities[0]
        
        # Add period filter if mentioned
        if state["query_analysis"].time_references:
            filters["fiscal_period"] = state["query_analysis"].time_references[0]
    
    # Execute retrieval
    results = await retrieval_pipeline.retrieve(
        query=state["current_query"],
        top_k=10,
        filters=filters if filters else None,
        use_hyde=state["query_analysis"].query_type == QueryType.ANALYTICAL
    )
    
    # Convert to dict format
    documents = [
        {
            "id": r.id,
            "content": r.content,
            "score": r.score,
            "metadata": r.metadata,
            "source": r.source
        }
        for r in results
    ]
    
    return {
        "retrieved_documents": documents,
        "filters": filters
    }
```

### 3. Grader Node

```python
GRADER_PROMPT = """You are a document relevance grader for a financial RAG system.

Evaluate if this document is relevant to answering the user's question.

Question: {question}

Document:
{document}

Consider:
1. Does this document contain information that helps answer the question?
2. Is the information from the correct company/time period?
3. What specific information does it provide?

Grade as 'relevant' if it contains useful information, 'irrelevant' otherwise."""

async def grader_node(state: AgenticRAGState) -> dict:
    """
    Grade retrieved documents for relevance.
    
    Returns:
        Updated state with document_grades and relevant_documents
    """
    
    llm = ChatGroq(model="llama-3.1-8b-instant", temperature=0)
    structured_llm = llm.with_structured_output(DocumentGrade)
    
    grades = []
    relevant_docs = []
    
    for doc in state["retrieved_documents"]:
        # Grade each document
        grade = await structured_llm.ainvoke(
            GRADER_PROMPT.format(
                question=state["original_query"],
                document=doc["content"][:2000]  # Truncate for speed
            )
        )
        grade.document_id = doc["id"]
        grades.append(grade)
        
        if grade.relevance == DocumentRelevance.RELEVANT:
            relevant_docs.append(doc)
    
    return {
        "document_grades": grades,
        "relevant_documents": relevant_docs
    }
```

### 4. Rewrite Node

```python
REWRITE_PROMPT = """You are a query rewriter for a financial RAG system.

The initial search for this query didn't find relevant documents:
"{original_query}"

Rewrite the query to improve retrieval. Consider:
1. Using different terminology (e.g., "revenue" vs "sales", "profit" vs "earnings")
2. Being more specific about the company or time period
3. Breaking down complex questions
4. Expanding abbreviations

Rewritten query:"""

async def rewrite_node(state: AgenticRAGState) -> dict:
    """
    Rewrite query for better retrieval.
    
    Returns:
        Updated state with new current_query and incremented rewrite_count
    """
    
    llm = ChatGroq(model="llama-3.1-8b-instant", temperature=0.3)
    
    response = await llm.ainvoke(
        REWRITE_PROMPT.format(original_query=state["original_query"])
    )
    
    return {
        "current_query": response.content.strip(),
        "rewrite_count": state["rewrite_count"] + 1
    }
```

### 5. Generate Node

```python
GENERATE_PROMPT = """You are a financial analyst assistant for NIFTY 50 companies.

Answer the user's question based ONLY on the provided context. 

Rules:
1. Only use information from the provided documents
2. Cite sources using [1], [2], etc.
3. If the context doesn't contain the answer, say so
4. Be precise with numbers and dates
5. Don't make up information

Question: {question}

Context:
{context}

Answer:"""

async def generate_node(state: AgenticRAGState) -> dict:
    """
    Generate answer from relevant documents.
    
    Returns:
        Updated state with generated_response
    """
    
    # Build context from relevant documents
    context_parts = []
    for i, doc in enumerate(state["relevant_documents"][:5]):
        source = doc["metadata"].get("source", "Unknown")
        context_parts.append(f"[{i+1}] Source: {source}\n{doc['content']}")
    
    context = "\n\n---\n\n".join(context_parts)
    
    # Generate with main model
    llm = ChatGroq(model="llama-3.3-70b-versatile", temperature=0)
    
    response = await llm.ainvoke(
        GENERATE_PROMPT.format(
            question=state["original_query"],
            context=context
        )
    )
    
    return {
        "generated_response": response.content,
        "generation_attempt": state["generation_attempt"] + 1
    }
```

### 6. Fact Check Node

```python
FACT_CHECK_PROMPT = """You are a fact checker for a financial RAG system.

Verify if the generated answer is faithful to the source documents.

Question: {question}

Generated Answer:
{answer}

Source Documents:
{sources}

Check each claim in the answer:
1. Is it supported by the sources?
2. Are numbers/dates accurate?
3. Is anything made up or hallucinated?

Be strict - if a claim isn't directly supported, mark it as unsupported."""

async def fact_check_node(state: AgenticRAGState) -> dict:
    """
    Check generated answer for hallucinations.
    
    Returns:
        Updated state with fact_check_result
    """
    
    llm = ChatGroq(model="llama-3.1-70b-versatile", temperature=0)
    structured_llm = llm.with_structured_output(FactCheckResult)
    
    # Build sources string
    sources = "\n\n".join([
        f"[{i+1}] {doc['content'][:1000]}"
        for i, doc in enumerate(state["relevant_documents"][:5])
    ])
    
    result = await structured_llm.ainvoke(
        FACT_CHECK_PROMPT.format(
            question=state["original_query"],
            answer=state["generated_response"],
            sources=sources
        )
    )
    
    return {
        "fact_check_result": result
    }
```

### 7. Citation Node

```python
async def citation_node(state: AgenticRAGState) -> dict:
    """
    Extract and format citations.
    
    Returns:
        Updated state with citations
    """
    
    citations = []
    
    # Parse citation markers from response
    import re
    citation_pattern = r'\[(\d+)\]'
    used_citations = set(re.findall(citation_pattern, state["generated_response"]))
    
    for idx_str in used_citations:
        idx = int(idx_str) - 1
        if 0 <= idx < len(state["relevant_documents"]):
            doc = state["relevant_documents"][idx]
            citations.append(Citation(
                claim=f"Reference [{idx_str}]",
                document_id=doc["id"],
                document_title=doc["metadata"].get("title", "Unknown"),
                source_text=doc["content"][:500],
                page_number=doc["metadata"].get("page_number")
            ))
    
    return {
        "citations": citations
    }
```

### 8. HITL Check Node

```python
async def hitl_check_node(state: AgenticRAGState) -> dict:
    """
    Determine if human review is needed.
    
    Triggers HITL for:
    1. Low confidence answers
    2. Sensitive topics
    3. Multiple rewrites/regenerations
    """
    
    requires_review = False
    reason = None
    
    # Check confidence
    if state["fact_check_result"] and state["fact_check_result"].confidence < 0.7:
        requires_review = True
        reason = f"Low confidence ({state['fact_check_result'].confidence:.2f})"
    
    # Check retry count
    if state["rewrite_count"] >= 2 or state["generation_attempt"] >= 2:
        requires_review = True
        reason = "Multiple retries needed"
    
    # Check for sensitive topics (simplified)
    sensitive_keywords = ["lawsuit", "fraud", "investigation", "scandal"]
    if any(kw in state["original_query"].lower() for kw in sensitive_keywords):
        requires_review = True
        reason = "Sensitive topic detected"
    
    return {
        "requires_human_review": requires_review,
        "hitl_reason": reason
    }
```

### 9. Web Search Node (Fallback)

```python
from langchain_community.tools.tavily_search import TavilySearchResults

async def web_search_node(state: AgenticRAGState) -> dict:
    """
    Fallback to web search for current events.
    
    Returns:
        Updated state with web search results as documents
    """
    
    search = TavilySearchResults(max_results=5)
    
    # Add NIFTY 50 context to query
    search_query = f"{state['current_query']} NIFTY 50 India stock market"
    
    results = await search.ainvoke(search_query)
    
    # Convert to document format
    documents = [
        {
            "id": f"web_{i}",
            "content": result["content"],
            "score": 1.0,
            "metadata": {
                "source": result["url"],
                "title": result.get("title", "Web Result"),
                "type": "web_search"
            },
            "source": "web"
        }
        for i, result in enumerate(results)
    ]
    
    return {
        "retrieved_documents": documents,
        "relevant_documents": documents  # Skip grading for web results
    }
```

### 10. Direct Answer Node

```python
DIRECT_ANSWER_PROMPT = """You are a financial education assistant.

Answer this general financial question without needing to search documents:
{question}

Provide a clear, educational explanation. If the question is about a specific
company or requires current data, say you need to search for that information."""

async def direct_answer_node(state: AgenticRAGState) -> dict:
    """
    Answer simple questions directly without retrieval.
    """
    
    llm = ChatGroq(model="llama-3.1-8b-instant", temperature=0)
    
    response = await llm.ainvoke(
        DIRECT_ANSWER_PROMPT.format(question=state["original_query"])
    )
    
    return {
        "generated_response": response.content,
        "citations": [],  # No citations for direct answers
        "fact_check_result": FactCheckResult(
            is_faithful=True,
            confidence=1.0,
            reasoning="Direct answer without document retrieval"
        )
    }
```

---

## Graph Construction

```python
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import MemorySaver
from typing import Literal

def create_rag_graph() -> StateGraph:
    """
    Create the agentic RAG workflow graph.
    """
    
    # Initialize graph with state schema
    workflow = StateGraph(AgenticRAGState)
    
    # ============= Add Nodes =============
    
    workflow.add_node("router", router_node)
    workflow.add_node("retrieve", retrieve_node)
    workflow.add_node("grade", grader_node)
    workflow.add_node("rewrite", rewrite_node)
    workflow.add_node("generate", generate_node)
    workflow.add_node("fact_check", fact_check_node)
    workflow.add_node("cite", citation_node)
    workflow.add_node("hitl_check", hitl_check_node)
    workflow.add_node("web_search", web_search_node)
    workflow.add_node("direct_answer", direct_answer_node)
    
    # ============= Add Edges =============
    
    # Entry point
    workflow.add_edge(START, "router")
    
    # Router conditional edges
    def route_query(state: AgenticRAGState) -> Literal["retrieve", "web_search", "direct_answer"]:
        route = state["route_decision"]
        if route == RouteDecision.VECTOR_STORE:
            return "retrieve"
        elif route == RouteDecision.WEB_SEARCH:
            return "web_search"
        else:
            return "direct_answer"
    
    workflow.add_conditional_edges(
        "router",
        route_query,
        {
            "retrieve": "retrieve",
            "web_search": "web_search",
            "direct_answer": "direct_answer"
        }
    )
    
    # Retrieve -> Grade
    workflow.add_edge("retrieve", "grade")
    
    # Grade conditional edges
    def grade_documents(state: AgenticRAGState) -> Literal["generate", "rewrite", "web_search"]:
        relevant_count = len(state["relevant_documents"])
        
        if relevant_count >= 2:
            return "generate"
        elif state["rewrite_count"] < state["max_rewrites"]:
            return "rewrite"
        else:
            return "web_search"  # Fallback to web
    
    workflow.add_conditional_edges(
        "grade",
        grade_documents,
        {
            "generate": "generate",
            "rewrite": "rewrite",
            "web_search": "web_search"
        }
    )
    
    # Rewrite -> Retrieve (loop back)
    workflow.add_edge("rewrite", "retrieve")
    
    # Web search -> Generate (skip grading)
    workflow.add_edge("web_search", "generate")
    
    # Generate -> Fact Check
    workflow.add_edge("generate", "fact_check")
    
    # Fact check conditional edges
    def check_facts(state: AgenticRAGState) -> Literal["cite", "generate"]:
        result = state["fact_check_result"]
        
        if result.is_faithful or state["generation_attempt"] >= state["max_generations"]:
            return "cite"
        else:
            return "generate"  # Regenerate
    
    workflow.add_conditional_edges(
        "fact_check",
        check_facts,
        {
            "cite": "cite",
            "generate": "generate"
        }
    )
    
    # Cite -> HITL Check
    workflow.add_edge("cite", "hitl_check")
    
    # Direct answer -> HITL Check (skip retrieval)
    workflow.add_edge("direct_answer", "hitl_check")
    
    # HITL Check -> END (or interrupt)
    workflow.add_edge("hitl_check", END)
    
    return workflow

# ============= Compile Graph =============

def compile_graph(checkpointer=None):
    """Compile the graph with optional checkpointer"""
    
    workflow = create_rag_graph()
    
    if checkpointer is None:
        checkpointer = MemorySaver()
    
    return workflow.compile(
        checkpointer=checkpointer,
        interrupt_before=["hitl_check"]  # Pause before HITL if needed
    )

# Create compiled graph
graph = compile_graph()
```

---

## Running the Workflow

### Basic Invocation

```python
async def run_query(
    question: str,
    user_id: Optional[int] = None,
    filters: Optional[dict] = None,
    thread_id: str = None
) -> dict:
    """
    Run a query through the RAG workflow.
    
    Args:
        question: User's question
        user_id: Optional user ID for tracking
        filters: Optional filters (company, period)
        thread_id: Thread ID for conversation continuity
    
    Returns:
        Final state with response
    """
    
    # Initial state
    initial_state = {
        "messages": [HumanMessage(content=question)],
        "original_query": question,
        "current_query": question,
        "query_analysis": None,
        "filters": filters,
        "retrieved_documents": [],
        "document_grades": [],
        "relevant_documents": [],
        "generated_response": None,
        "fact_check_result": None,
        "citations": [],
        "route_decision": None,
        "rewrite_count": 0,
        "generation_attempt": 0,
        "max_rewrites": 2,
        "max_generations": 2,
        "requires_human_review": False,
        "hitl_reason": None,
        "trace_id": str(uuid.uuid4()),
        "user_id": user_id,
        "started_at": datetime.utcnow().isoformat(),
        "error": None
    }
    
    # Config for thread
    config = {
        "configurable": {
            "thread_id": thread_id or str(uuid.uuid4())
        }
    }
    
    # Run graph
    final_state = await graph.ainvoke(initial_state, config)
    
    return final_state
```

### Streaming Response

```python
async def stream_query(
    question: str,
    thread_id: str = None
):
    """
    Stream the query execution for real-time updates.
    
    Yields:
        Node updates as they happen
    """
    
    initial_state = {
        "messages": [HumanMessage(content=question)],
        "original_query": question,
        "current_query": question,
        # ... other initial state
    }
    
    config = {"configurable": {"thread_id": thread_id or str(uuid.uuid4())}}
    
    async for event in graph.astream(initial_state, config, stream_mode="updates"):
        # event is {node_name: state_update}
        for node_name, update in event.items():
            yield {
                "node": node_name,
                "update": update
            }
```

### HITL Handling

```python
async def handle_hitl_interrupt(
    thread_id: str,
    decision: Literal["approve", "reject", "edit"],
    edited_response: Optional[str] = None
) -> dict:
    """
    Handle human-in-the-loop interrupt.
    
    Args:
        thread_id: Thread ID of interrupted workflow
        decision: Human decision
        edited_response: Optional edited response
    
    Returns:
        Final state after resuming
    """
    
    config = {"configurable": {"thread_id": thread_id}}
    
    # Get current state
    state = await graph.aget_state(config)
    
    if decision == "approve":
        # Resume with current state
        final_state = await graph.ainvoke(None, config)
    
    elif decision == "reject":
        # Mark as rejected and end
        state.values["error"] = "Rejected by human reviewer"
        final_state = state.values
    
    elif decision == "edit" and edited_response:
        # Update response and resume
        state.values["generated_response"] = edited_response
        await graph.aupdate_state(config, state.values)
        final_state = await graph.ainvoke(None, config)
    
    return final_state
```

---

## Error Handling

```python
from langgraph.errors import GraphRecursionError

async def safe_run_query(question: str, **kwargs) -> dict:
    """
    Run query with error handling.
    """
    
    try:
        return await run_query(question, **kwargs)
    
    except GraphRecursionError:
        return {
            "error": "Query exceeded maximum iterations",
            "generated_response": "I apologize, but I couldn't find a satisfactory answer after multiple attempts. Please try rephrasing your question.",
            "citations": []
        }
    
    except Exception as e:
        logger.exception(f"Error in RAG workflow: {e}")
        return {
            "error": str(e),
            "generated_response": "An error occurred while processing your question. Please try again.",
            "citations": []
        }
```

---

## Observability

### LangSmith Integration

```python
import os
from langsmith import Client

# Enable tracing
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_PROJECT"] = "nifty50-rag"

# Custom run metadata
async def run_with_tracing(question: str, **kwargs):
    """Run with LangSmith tracing"""
    
    from langchain_core.tracers import LangChainTracer
    
    tracer = LangChainTracer(
        project_name="nifty50-rag",
        tags=["production"],
        metadata={
            "user_id": kwargs.get("user_id"),
            "filters": kwargs.get("filters")
        }
    )
    
    config = {
        "configurable": {"thread_id": str(uuid.uuid4())},
        "callbacks": [tracer]
    }
    
    return await graph.ainvoke(
        create_initial_state(question, **kwargs),
        config
    )
```

---

## Configuration

```python
# config.py

RAG_CONFIG = {
    # Retrieval
    "retrieval_top_k": 10,
    "rerank_top_k": 5,
    "use_hyde": True,
    "expand_parents": True,
    
    # Generation
    "generation_model": "llama-3.3-70b-versatile",
    "generation_temperature": 0,
    "max_context_tokens": 6000,
    
    # Control flow
    "max_rewrites": 2,
    "max_generations": 2,
    "min_relevant_docs": 2,
    
    # HITL
    "hitl_confidence_threshold": 0.7,
    "hitl_sensitive_topics": ["lawsuit", "fraud", "investigation"],
    
    # Timeouts
    "llm_timeout_seconds": 30,
    "retrieval_timeout_seconds": 10
}
```

---

## Next Document

Continue to [06-API-SPECIFICATION.md](./06-API-SPECIFICATION.md) for REST API endpoints.

