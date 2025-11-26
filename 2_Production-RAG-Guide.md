**The** **Ultimate** **Production-Ready** **Agentic** **RAG**
**System:** **A** **Comprehensive** **Guide**

**Executive** **Summary**

This document provides a complete blueprint for building an
enterprise-grade, production-ready agentic Retrieval-Augmented
Generation (RAG) system using LangChain v1 and LangGraph. It combines
the latest advancements in context engineering, document parsing,
multi-agent orchestration, safety guardrails, human-in-the-loop
controls, and evaluation methodologies to create what we term "the
overkill RAG"—a system optimized for reliability, safety, and
performance across complex, heterogeneous document collections.

**Key** **Principles**

> **Context** **Engineering**: Dynamically control what the LLM sees at
> each step
>
> **Adaptive** **Parsing**: Handle structured and unstructured data
> intelligently
>
> **Safety** **First**: Layer deterministic and model-based guardrails
>
> **Human** **Oversight**: Interrupt-based controls for sensitive
> operations
>
> **Continuous** **Evaluation**: Monitor and improve system performance
>
> **Multi-Agent** **Orchestration**: Coordinate specialized agents for
> complex tasks

**Part** **1:** **Foundation** **Architecture**

**1.1** **System** **Components** **Overview**

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

**Part** **2:** **Advanced** **Document** **Processing** **Pipeline**

**2.1** **Parsing** **Strategies** **for** **Mixed** **Content**

Different document types require different parsing approaches.
Production systems must handle PDFs, HTML, Markdown, images with OCR,
tables, and more.

||
||
||
||
||
||
||
||

**Document** **Partitioning** **Best** **Practice**

Use Unstructured's partitioning for intelligent element extraction:

> from unstructured.partition.auto import partition
>
> \# Automatically detects document type and partitions elements =
> partition("document.pdf")
>
> \# Elements retain type: Title, Section, Paragraph, Table, etc. for
> element in elements:
>
> print(f"{element.type}: {element.text\[:100\]}") \# Preserve metadata
>
> if hasattr(element, 'metadata'):
>
> print(f" Source: {element.metadata.source}")

**2.2** **Comprehensive** **Chunking** **Strategies**

Production RAG systems must support multiple chunking approaches
optimized for different query patterns.

**Strategy** **1:** **Recursive** **Character** **Splitting**
**(Baseline)**

Best for: General text with paragraph structure

> from langchain_text_splitters import RecursiveCharacterTextSplitter
>
> splitter = RecursiveCharacterTextSplitter.from_tiktoken_encoder(
>
> chunk_size=512, chunk_overlap=50,
>
> separators=\[

\# tokens

\# maintain context

> "\n\n", \# Paragraph breaks
>
> "\n", \# Line breaks ".", \# Sentences
>
> " " \# Words \]
>
> )
>
> doc_splits = splitter.split_documents(docs)

**Tuning** **Parameters:**

> Start with 512 tokens (≈2000 chars) for general use
>
> Increase to 768-1024 for knowledge-dense content
>
> Decrease to 256-384 for FAQ/Q&A style docs
>
> Overlap: 10-20% typically optimal

**Strategy** **2:** **Semantic** **Chunking** **(Advanced)**

Best for: Complex documents requiring topic-aware boundaries

> from langchain_experimental.text_splitter import SemanticChunker from
> langchain_openai import OpenAIEmbeddings
>
> \# Uses embeddings to find semantic boundaries semantic_splitter =
> SemanticChunker(
>
> embeddings=OpenAIEmbeddings(), breakpoint_threshold_type="percentile",
> \# percentile or std_dev breakpoint_threshold_amount=95 \# Keep chunks
> cohesive
>
> )
>
> chunks = semantic_splitter.split_documents(docs)

**Advantages**: Respects topic transitions, prevents mid-concept splits
**Trade-off**: Higher computational cost, more API calls

**Strategy** **3:** **Markdown** **Header-Aware** **Chunking**

Best for: Markdown, HTML with clear section structure

> from langchain_text_splitters import MarkdownHeaderTextSplitter
>
> headers_to_split_on = \[ ("#", "Header 1"), ("##", "Header 2"),
> ("###", "Header 3"),
>
> \]
>
> markdown_splitter =
> MarkdownHeaderTextSplitter(headers_to_split_on=headers_to_split_on)
>
> \# Preserves hierarchical structure as metadata doc_splits =
> markdown_splitter.split_text(text)
>
> \# Each chunk retains parent headers
>
> for chunk in doc_splits:
>
> print(chunk.metadata) \# {"Header 1": "...", "Header 2": "..."}

**Strategy** **4:** **Hierarchical** **Chunking** **with** **Multiple**
**Levels**

Best for: Large, complex documents (manuals, regulations, research
papers)

> class HierarchicalChunker:
>
> """Creates multiple chunk levels for flexible retrieval"""
>
> def chunk_hierarchically(self, doc, chunk_sizes=\[256, 512, 1024\]):
> """
>
> Create overlapping chunks at multiple granularity levels: - Level 1:
> 256 tokens (detailed facts)
>
> \- Level 2: 512 tokens (concepts) - Level 3: 1024 tokens (sections)
> """
>
> all_chunks = \[\]
>
> for size in chunk_sizes:
>
> splitter = RecursiveCharacterTextSplitter.from_tiktoken_encoder(
> chunk_size=size,
>
> chunk_overlap=size // 5 )
>
> chunks = splitter.split_documents(\[doc\]) for chunk in chunks:
>
> chunk.metadata\['chunk_level'\] = size all_chunks.extend(chunks)
>
> return all_chunks

**2.3** **Handling** **Structured** **Data** **(Tables)** **in** **RAG**

Tables require special treatment—storing them as text loses structure.

**Approach** **1:** **Preserve** **Table** **Representation**

> def extract_and_preserve_tables(elements):
>
> """Keep tables as structured data, not flattened text""" chunks = \[\]
>
> for element in elements:
>
> if element.type == "Table":
>
> \# Store table as Markdown for structure preservation table_md =
> element.metadata.text_as_markdown chunks.append(Document(
>
> page_content=table_md, metadata={
>
> 'type': 'table',
>
> 'source': element.metadata.source, 'table_name':
> extract_table_name(element)
>
> } ))
>
> else:
>
> chunks.append(Document(page_content=element.text))
>
> return chunks

**Benefit**: LLM understands column headers, row relationships
**Trade-off**: Larger chunks

**Approach** **2:** **Hybrid** **Table** **Representation**

> def hybrid_table_embedding(table_element):
>
> """Create both semantic and explicit representations"""
>
> table_md = element.metadata.text_as_markdown
>
> table_summary = generate_table_summary(table_element) \# LLM summary
>
> return {
>
> 'full_table': table_md,
>
> 'summary': table_summary,

\# For exact retrieval

> \# For semantic search
>
> 'column_names': extract_columns(table_element), 'key_metrics':
> extract_key_values(table_element)
>
> }

**2.4** **Metadata** **Attachment** **for** **Enhanced** **Retrieval**

Rich metadata enables filtering and context injection.

> def attach_comprehensive_metadata(document, source_path): """Attach
> all relevant metadata for production filtering"""
>
> document.metadata.update({ \# Source tracking 'source': source_path,
>
> 'document_id': hash_document(source_path), 'chunk_index': i,
>
> \# Temporal
>
> 'ingestion_date': datetime.now().isoformat(), 'document_date':
> extract_date(document),
>
> \# Content type
>
> 'content_type': detect_type(document), \# 'policy', 'faq', 'procedure'
> 'has_tables': contains_tables(document),
>
> 'has_images': contains_images(document),
>
> \# Semantic tags (extracted by LLM)
>
> 'semantic_tags': extract_topics(document), \# \['billing', 'payment'\]
> 'confidence': 0.95,
>
> \# Access control 'access_level': 'public',
>
> 'department': extract_department(source_path),
>
> \# Relationships
>
> 'related_documents': find_related_ids(document), 'parent_section':
> extract_section_header(document),
>
> })
>
> return document

**Part** **3:** **Intelligent** **Retrieval** **System**

**3.1** **Hybrid** **Search** **Architecture**

Combining semantic (vector) and sparse (BM25) search improves recall
significantly.

||
||
||
||
||
||

**Implementation:** **Hybrid** **Retriever** **with** **Fusion**

> from langchain.retrievers import EnsembleRetriever, BM25Retriever from
> langchain_community.vectorstores import Qdrant
>
> class HybridRAGRetriever:
>
> def \_\_init\_\_(self, docs, embeddings_model): \# Semantic retriever
> (vector)
>
> self.vector_store = Qdrant.from_documents( docs,
>
> embeddings=embeddings_model, prefer_grpc=True \# Performance
>
> )
>
> self.semantic_retriever = self.vector_store.as_retriever(
> search_kwargs={"k": 10}
>
> )
>
> \# Sparse retriever (BM25)
>
> self.sparse_retriever = BM25Retriever.from_documents(docs)
> self.sparse_retriever.k = 10
>
> \# Ensemble with RRF (Reciprocal Rank Fusion) self.hybrid_retriever =
> EnsembleRetriever(
>
> retrievers=\[self.semantic_retriever, self.sparse_retriever\],
> weights=\[0.6, 0.4\] \# Weight semantic higher
>
> )
>
> def retrieve_with_reranking(self, query, top_k=5): """Retrieve +
> rerank for better precision""" candidates =
> self.hybrid_retriever.invoke(query)
>
> \# Rerank using cross-encoder
>
> reranked = self.reranker.rank(query, candidates) return
> reranked\[:top_k\]

**3.2** **Re-ranking** **Strategy**

Re-ranking significantly improves precision (recall already maximized by
hybrid search).

> from sentence_transformers import CrossEncoder
>
> class ProductionReranker: def \_\_init\_\_(self):
>
> \# Cross-encoder trained on relevance
>
> self.model =
> CrossEncoder('cross-encoder/mmarco-mMiniLMv2-L12-H384-v1')
>
> def rerank(self, query, candidates, top_k=5): """Re-score candidates
> with cross-encoder"""
>
> pairs = \[\[query, doc.page_content\] for doc in candidates\] scores =
> self.model.predict(pairs)
>
> \# Sort by score descending ranked = sorted(
>
> zip(candidates, scores), key=lambda x: x\[^1\], reverse=True
>
> )
>
> \# Attach scores to metadata
>
> for doc, score in ranked\[:top_k\]: doc.metadata\['rerank_score'\] =
> float(score)
>
> return \[doc for doc, score in ranked\[:top_k\]\]

**Part** **4:** **Context** **Engineering** **for** **Reliability**

Context engineering—providing the right information in the right
format—is the \#1 factor in agent reliability.

**4.1** **Dynamic** **System** **Prompts**

System prompts should adapt based on conversation state, not be static.

||
||
||
||
||
||
||
||

> from langchain.agents.middleware import dynamic_prompt, ModelRequest
>
> @dynamic_prompt
>
> def state_aware_system_prompt(request: ModelRequest) -&gt; str:
> """Dynamically adjust system prompt based on context"""
>
> message_count = len(request.messages)
>
> user_profile = request.state.get('user_profile', {})
> conversation_stage = request.state.get('stage', 'initial')
>
> base_prompt = """You are an expert RAG assistant. Your role is to: 1.
> Retrieve relevant information from the knowledge base
>
> 2\. Synthesize accurate answers with proper citations 3. Flag
> uncertain information
>
> 4\. Maintain conversation context"""
>
> \# Adjust based on conversation length if message_count &gt; 20:
>
> base_prompt += "\n\n⚠ LONG CONVERSATION: Be concise. Focus only on new
> informati
>
> \# Adjust based on user expertise
>
> if user_profile.get('expertise') == 'advanced':
>
> base_prompt += "\n\nUser is technical. Use precise terminology,
> include implement else:
>
> base_prompt += "\n\nUser is non-technical. Use simple language,
> provide analogies
>
> \# Adjust based on conversation stage
>
> if conversation_stage == 'error_recovery':
>
> base_prompt += "\n\nWe encountered an error. Provide clearer reasoning
> and offer
>
> return base_prompt
>
> agent = create_agent( model="gpt-4o", tools=\[...\],
>
> middleware=\[state_aware_system_prompt\] )

**4.2** **Transient** **vs.** **Persistent** **Context** **Updates**

Understanding this distinction is critical for production systems.

||
||
||
||
||

> \# TRANSIENT: Inject file context for this call only @wrap_model_call
>
> def inject_file_context(request: ModelRequest, handler): """Transient:
> doesn't modify state"""
>
> uploaded_files = request.state.get("uploaded_files", \[\])
>
> if uploaded_files:
>
> file_desc = "\n".join(f"- {f\['name'\]}" for f in uploaded_files)
> messages = request.messages + \[{
>
> "role": "user",
>
> "content": f"Available files this session:\n{file_desc}" }\]
>
> request = request.override(messages=messages)
>
> return handler(request)
>
> \# PERSISTENT: Summarize and save to state @wrap_model_call
>
> def persistent_conversation_summary(request, handler): """Persistent:
> modifies and saves to state"""
>
> from langchain.agents.middleware import SummarizationMiddleware
>
> \# Saves summary back to state for future turns return
> handler(request)

**4.3** **Tool** **Selection** **and** **Access** **Control**

Not all tools should be available in all contexts.

> @wrap_model_call
>
> def dynamic_tool_selection(request: ModelRequest, handler):
>
> """Enable tools based on auth, conversation stage, feature flags"""
>
> state = request.state
>
> is_authenticated = state.get('authenticated', False) message_count =
> len(state\['messages'\])
>
> user_role = state.get('user_role', 'user')
>
> available_tools = \[\]
>
> for tool in request.tools:
>
> \# Check authentication
>
> if tool.requires_auth and not is_authenticated: continue
>
> \# Check message count (don't give dangerous tools immediately) if
> tool.is_dangerous and message_count &lt; 2:
>
> continue
>
> \# Check role
>
> if tool.required_role and user_role not in tool.required_role:
> continue
>
> available_tools.append(tool)
>
> request = request.override(tools=available_tools) return
> handler(request)
>
> agent = create_agent( model="gpt-4o",
>
> tools=\[search_tool, write_file_tool, delete_file_tool\],
> middleware=\[dynamic_tool_selection\]
>
> )

**Part** **5:** **Multi-Agent** **Orchestration** **with** **LangGraph**

**5.1** **The** **Agentic** **RAG** **Workflow**

A production-grade agentic RAG goes beyond simple retrieval:

> User Query ↓
>
> \[Query Analysis\] ← Decide: retrieve, decompose, or respond directly?
> ↓
>
> ├─→ \[Decompose\] ← For complex queries requiring sub-questions │ ↓
>
> │ \[Sub-Question Retrieval\] ← Retrieve for each sub-question │ ↓
>
> ├─→ \[Retrieval\] ← Standard semantic/hybrid retrieval │ ↓
>
> ├─→ \[Grade Documents\] ← Binary relevance check │ ├─→ Not Relevant?
> \[Rewrite Query\]
>
> │ └─→ Relevant? Continue │ ↓
>
> ├─→ \[Context Injection\] ← Add guardrails, format │ ↓
>
> ├─→ \[Generation with Reflection\] ← Generate answer + self-check │ ↓
>
> ├─→ \[Fact Verification\] ← Check claims against sources
>
> │ ├─→ Hallucination Detected? \[Regenerate with Constraints\] │ └─→
> Verified? Continue
>
> │ ↓
>
> └─→ \[Response Formulation\] ← Final answer with citations ↓
>
> \[Human Review\] ← For sensitive responses (HITL) ↓
>
> Response to User

**5.2** **Complete** **LangGraph** **Implementation**

> from langgraph.graph import StateGraph, START, END
>
> from langgraph.prebuilt import ToolNode, tools_condition from typing
> import Literal
>
> from pydantic import BaseModel, Field
>
> class QueryAnalysisOutput(BaseModel):
>
> """Analysis of whether to retrieve or respond"""
>
> should_retrieve: bool = Field(description="Whether retrieval is
> needed") query_type: Literal\["direct", "complex", "clarification"\] =
> Field(
>
> description="Type of query" )
>
> sub_questions: list\[str\] = Field( default_factory=list,
>
> description="Sub-questions if complex query" )
>
> class DocumentGrade(BaseModel):
>
> """Relevance judgment for retrieved documents""" binary_score:
> Literal\["yes", "no"\] = Field(
>
> description="Is document relevant to question?" )
>
> class FactVerification(BaseModel): """Verify claims made in
> response""" has_hallucinations: bool
>
> unsupported_claims: list\[str\] = Field(default_factory=list)
> verification_score: float \# 0-1
>
> class AgenticRAGState(MessagesState):
>
> """Complete state for agentic RAG workflow""" query_analysis:
> QueryAnalysisOutput \| None = None retrieved_documents: list =
> Field(default_factory=list)
>
> document_grades: list\[DocumentGrade\] = Field(default_factory=list)
> rewrite_count: int = 0
>
> generation_attempt: int = 0
>
> fact_check_result: FactVerification \| None = None final_response: str
> \| None = None
>
> citations: list\[dict\] = Field(default_factory=list)
>
> \# ============= NODES =============
>
> def analyze_query(state: AgenticRAGState) -&gt; dict: """Step 1:
> Analyze whether retrieval is needed"""
>
> question = state\["messages"\]\[^0\].content
>
> analysis_prompt = f"""Analyze this query: "{question}"

Decide:

1\. Should we retrieve documents? (direct answer vs. knowledge lookup)
2. Is this a complex query needing decomposition?

3\. What are the sub-questions if complex?"""

> response = query_analyzer_model.with_structured_output(
> QueryAnalysisOutput
>
> ).invoke(\[{"role": "user", "content": analysis_prompt}\])
>
> return {
>
> "query_analysis": response, "messages": state\["messages"\]
>
> }

def decompose_query(state: AgenticRAGState) -&gt; dict:

> """Step 2a: For complex queries, decompose into sub-questions"""
>
> question = state\["messages"\]\[^0\].content

decomposition_prompt = f"""Break down this complex query into simpler
sub-questions: "{question}"

Format each as a clear, independent question."""

> response = response_model.invoke(\[{"role": "user", "content":
> decomposition_prompt}\])
>
> return {
>
> "messages": state\["messages"\] + \[response\] }

def retrieve_documents(state: AgenticRAGState) -&gt; dict: """Step 2b:
Retrieve documents using hybrid search"""

> question = state\["messages"\]\[^0\].content
>
> \# Get sub-questions if decomposed
>
> sub_questions = state\["query_analysis"\].sub_questions if
> state\["query_analysis"\].sub\_
>
> all_docs = \[\]
>
> for sub_q in sub_questions:
>
> docs = hybrid_retriever.retrieve_with_reranking(sub_q, top_k=5)
> all_docs.extend(docs)
>
> \# Deduplicate while preserving score unique_docs = {}
>
> for doc in all_docs:
>
> key = hash(doc.page_content)
>
> if key not in unique_docs or doc.metadata.get('rerank_score', 0) &gt;
> unique_docs unique_docs\[key\] = doc
>
> docs_content = "\n\n---\n\n".join(\[
>
> f"\[Source: {doc.metadata.get('source',
> 'Unknown')}\]\n{doc.page_content}" for doc in
> list(unique_docs.values())\[:10\]
>
> \])
>
> tool_message = ToolMessage(
>
> content=docs_content, name="retrieve_documents"
>
> )
>
> return {
>
> "retrieved_documents": list(unique_docs.values()), "messages":
> state\["messages"\] + \[tool_message\]
>
> }

def grade_documents(state: AgenticRAGState) -&gt;
Literal\["generate_answer", "rewrite_que """Step 3: Grade retrieved
documents for relevance"""

> question = state\["messages"\]\[^0\].content documents =
> state.get("retrieved_documents", \[\])
>
> grades = \[\] relevant_docs = \[\]
>
> for doc in documents:
>
> grade_prompt = f"""Is this document relevant to the question?

Question: {question}

Document: {doc.page_content\[:500\]}...

Answer 'yes' if relevant, 'no' if not."""

> grade = grader_model.with_structured_output(DocumentGrade).invoke(\[
> {"role": "user", "content": grade_prompt}
>
> \])
>
> grades.append(grade)
>
> if grade.binary_score == "yes": relevant_docs.append(doc)
>
> if relevant_docs:
>
> return "generate_answer" else:
>
> return "rewrite_query"

def rewrite_query(state: AgenticRAGState) -&gt; dict: """Step 4: If
documents irrelevant, rewrite the query"""

> if state\["rewrite_count"\] &gt;= 2: \# Tried twice, give up
>
> return {
>
> "messages": state\["messages"\] + \[AIMessage(
>
> content="I couldn't find relevant information to answer your question.
> Pl )\]
>
> }
>
> question = state\["messages"\]\[^0\].content

rewrite_prompt = f"""The initial retrieval for this question didn't find
relevant doc "{question}"

Formulate an improved version that might retrieve better results."""

> new_question = response_model.invoke(\[{"role": "user", "content":
> rewrite_prompt}\])
>
> return {
>
> "rewrite_count": state\["rewrite_count"\] + 1, "messages":
> state\["messages"\] + \[new_question\], "retrieved_documents": \[\] \#
> Reset for new retrieval
>
> }

def generate_answer_with_reflection(state: AgenticRAGState) -&gt; dict:
"""Step 5: Generate answer with internal verification"""

> question = state\["messages"\]\[^0\].content documents =
> state.get("retrieved_documents", \[\])
>
> context = "\n\n---\n\n".join(\[
>
> f"\[{i+1}\] {doc.page_content\[:1000\]}\n(Source:
> {doc.metadata.get('source')})" for i, doc in
> enumerate(documents\[:5\])
>
> \])
>
> generation_prompt = f"""Based on the provided context, answer this
> question:

Question: {question}

Context: {context}

Requirements:

1\. Cite specific sources \[^1\], \[^2\], etc. 2. Flag any assumptions

3\. Be concise and accurate

4\. Don't make up information"""

> answer = response_model.invoke(\[{"role": "user", "content":
> generation_prompt}\])
>
> return {
>
> "generation_attempt": state\["generation_attempt"\] + 1, "messages":
> state\["messages"\] + \[answer\], "final_response": answer.content
>
> }

def verify_facts(state: AgenticRAGState) -&gt; Literal\["respond",
"regenerate_with_constr """Step 6: Verify generated response against
source documents"""

> response_text = state\["final_response"\] documents =
> state.get("retrieved_documents", \[\])
>
> doc_context = "\n".join(\[doc.page_content for doc in documents\])
>
> verification_prompt = f"""Check if this response is supported by the
> source documents

Response: {response_text}

Source Documents: {doc_context}

Report any hallucinations or unsupported claims."""

> verification =
> fact_verifier_model.with_structured_output(FactVerification).invoke(\[
> {"role": "user", "content": verification_prompt}
>
> \])
>
> if verification.has_hallucinations: return
> "regenerate_with_constraints"
>
> else:
>
> return "respond"

def regenerate_with_constraints(state: AgenticRAGState) -&gt; dict:

> """Step 7: If hallucinations detected, regenerate with stricter
> constraints"""
>
> if state\["generation_attempt"\] &gt;= 2:
>
> \# Use the previous response but add hallucination warning return {
>
> "final_response": state\["final_response"\] + "\n\n⚠ Warning: Some
> claims may }
>
> documents = state.get("retrieved_documents", \[\]) question =
> state\["messages"\]\[^0\].content
>
> unsupported = state\["fact_check_result"\].unsupported_claims if
> state\["fact_check_resu

regen_prompt = f"""Regenerate answer being VERY careful about these
unsupported claim {', '.join(unsupported)}

Only use facts directly supported by these documents:

{' '.join(\[doc.page_content for doc in documents\[:3\]\])}"""

> answer = response_model.invoke(\[{"role": "user", "content":
> regen_prompt}\])
>
> return {
>
> "generation_attempt": state\["generation_attempt"\] + 1,
> "final_response": answer.content,
>
> "messages": state\["messages"\] + \[answer\] }

def extract_citations(state: AgenticRAGState) -&gt; dict: """Step 8:
Extract and format citations"""

> response = state\["final_response"\]
>
> documents = state.get("retrieved_documents", \[\])
>
> citations = \[\]
>
> for i, doc in enumerate(documents): citations.append({
>
> "index": i + 1,
>
> "source": doc.metadata.get('source', 'Unknown'), "page":
> doc.metadata.get('page', ''), "content_preview":
> doc.page_content\[:100\]
>
> })
>
> return {
>
> "citations": citations
>
> }

\# ============= BUILD GRAPH =============

workflow = StateGraph(AgenticRAGState)

\# Add nodes

workflow.add_node("analyze_query", analyze_query)
workflow.add_node("decompose_query", decompose_query)
workflow.add_node("retrieve_documents", retrieve_documents)

workflow.add_node("grade_documents_node", lambda s: grade_documents(s))
\# Dummy wrapper workflow.add_node("rewrite_query_node", rewrite_query)
workflow.add_node("generate_answer", generate_answer_with_reflection)
workflow.add_node("verify_facts_node", lambda s: verify_facts(s)) \#
Dummy wrapper workflow.add_node("regenerate",
regenerate_with_constraints) workflow.add_node("extract_citations",
extract_citations)

\# Add edges

workflow.add_edge(START, "analyze_query")

def route_from_analysis(state: AgenticRAGState) -&gt; str: """Route
based on query analysis"""

> if state\["query_analysis"\].should_retrieve: if
> state\["query_analysis"\].sub_questions:
>
> return "decompose_query" else:
>
> return "retrieve_documents" else:
>
> return "generate_answer"

workflow.add_conditional_edges( "analyze_query", route_from_analysis

)

workflow.add_edge("decompose_query", "retrieve_documents")
workflow.add_conditional_edges(

> "retrieve_documents",

lambda s: "grade_documents_node" )

workflow.add_conditional_edges( "grade_documents_node", lambda s:
grade_documents(s)

)

workflow.add_edge("rewrite_query_node", "retrieve_documents")
workflow.add_edge("generate_answer", "verify_facts_node")

workflow.add_conditional_edges( "verify_facts_node",

lambda s: verify_facts(s) )

workflow.add_edge("regenerate", "extract_citations")
workflow.add_edge("extract_citations", END)

> \# Compile
>
> graph = workflow.compile()

**Part** **6:** **Safety,** **Guardrails** **&** **Human-in-the-Loop**

**6.1** **Layered** **Guardrails** **Architecture**

Production RAG systems require defense-in-depth with multiple guardrail
layers.

||
||
||
||
||
||
||
||

**Layer** **1:** **Deterministic** **Input** **Filtering**

> from langchain.agents.middleware import AgentMiddleware, hook_config
>
> class InputFilterMiddleware(AgentMiddleware):
>
> """Block dangerous input patterns deterministically"""
>
> def \_\_init\_\_(self, blocked_patterns: list\[str\]):
> super().\_\_init\_\_()
>
> self.blocked_patterns = blocked_patterns
>
> @hook_config(can_jump_to=\["end"\])
>
> def before_agent(self, state: AgentState, runtime) -&gt; dict \| None:
> if not state\["messages"\]:
>
> return None
>
> user_input = state\["messages"\]\[^0\].content.lower()
>
> for pattern in self.blocked_patterns: if pattern.lower() in
> user_input:
>
> return { "messages": \[{
>
> "role": "assistant",
>
> "content": "This request contains potentially unsafe patterns. Pl }\],
>
> "jump_to": "end" }
>
> return None
>
> \# Use it
>
> middleware = InputFilterMiddleware(
>
> blocked_patterns=\["DROP TABLE", "DELETE", "rm -rf"\] )

**Layer** **2:** **PII** **Detection** **&** **Masking**

> from langchain.agents.middleware import PIIMiddleware
>
> agent = create_agent( model="gpt-4o",
>
> tools=\[search_tool, send_email_tool\], middleware=\[
>
> \# Redact emails in input
>
> PIIMiddleware("email", strategy="redact", apply_to_input=True),
>
> \# Mask credit cards
>
> PIIMiddleware("credit_card", strategy="mask", apply_to_input=True),
>
> \# Block API keys PIIMiddleware(
>
> "api_key",
>
> detector=r"sk-\[a-zA-Z0-9\]{32}", strategy="block",
> apply_to_input=True
>
> ),
>
> \# Also check model output
>
> PIIMiddleware("email", strategy="redact", apply_to_output=True), \]
>
> )

**Layer** **3:** **Dynamic** **Tool** **Access** **Control**

> @wrap_model_call
>
> def smart_tool_selector(request: ModelRequest, handler): """Enable
> tools based on context, auth, and sensitivity"""
>
> state = request.state
>
> user_role = state.get('user_role', 'viewer') auth_level =
> state.get('auth_level', 0)
>
> \# Tool access matrix tool_access = {
>
> 'search': {'min_auth': 0, 'roles': \['viewer', 'editor', 'admin'\]},
> 'read_file': {'min_auth': 1, 'roles': \['editor', 'admin'\]},
> 'write_file': {'min_auth': 2, 'roles': \['admin'\]},
>
> 'delete_file': {'min_auth': 3, 'roles': \['admin'\]}, }
>
> available_tools = \[\]
>
> for tool in request.tools:
>
> access = tool_access.get(tool.name, {})
>
> if auth_level &lt; access.get('min_auth', 0):
>
> continue
>
> if user_role not in access.get('roles', \[\]): continue
>
> available_tools.append(tool)
>
> request = request.override(tools=available_tools) return
> handler(request)

**Layer** **4:** **Human-in-the-Loop** **for** **Sensitive**
**Operations**

> from langchain.agents.middleware import HumanInTheLoopMiddleware from
> langgraph.checkpoint.postgres import AsyncPostgresSaver
>
> agent = create_agent( model="gpt-4o",
>
> tools=\[search_tool, send_email_tool, delete_database_tool\],
> middleware=\[
>
> HumanInTheLoopMiddleware( interrupt_on={
>
> \# Require approval for these tools "send_email": True,
> "delete_database": True,
>
> "modify_sensitive_data": {"allowed_decisions": \["approve",
> "reject"\]},
>
> \# Auto-approve safe operations "search": False,
>
> "read_file": False, },
>
> description_prefix="⚠ Action requires approval" ),
>
> \],
>
> \# Must use persistent checkpointer for HITL
> checkpointer=AsyncPostgresSaver("postgres://...")
>
> )
>
> \# Usage with interrupts
>
> config = {"configurable": {"thread_id": "conversation_123"}}
>
> \# Run until interrupt result = agent.invoke(
>
> {"messages": \[{"role": "user", "content": "Send a confirmation
> email"}\]}, config=config
>
> )
>
> \# If interrupted, present to human if "\_\_interrupt\_\_" in result:
>
> interrupt_info = result\["\_\_interrupt\_\_"\]
>
> \# Show to human: action_requests, review_configs
>
> \# Human decides... \# Then resume
>
> from langgraph.types import Command
>
> result = agent.invoke(
>
> Command(resume={"decisions": \[{"type": "approve"}\]}), config=config
>
> )

**Layer** **5:** **Model-Based** **Output** **Verification**

> class OutputSafetyMiddleware(AgentMiddleware): """Use LLM to verify
> response safety"""
>
> def \_\_init\_\_(self): super().\_\_init\_\_()
>
> self.safety_model = init_chat_model("gpt-4o-mini")
>
> @hook_config(can_jump_to=\["end"\])
>
> def after_agent(self, state: AgentState, runtime) -&gt; dict \| None:
> if not state\["messages"\]:
>
> return None
>
> last_msg = state\["messages"\]\[-1\]
>
> if not isinstance(last_msg, AIMessage): return None
>
> \# Verify safety
>
> safety_check = self.safety_model.invoke(\[{ "role": "user",
>
> "content": f"""Check if this response is safe and appropriate:
>
> Response: {last_msg.content\[:1000\]}
>
> Respond with SAFE or UNSAFE and brief reason.""" }\])
>
> if "UNSAFE" in safety_check.content: \# Block unsafe content
>
> last_msg.content = "I cannot provide that response. Please ask
> something else
>
> return None

**Part** **7:** **Evaluation** **&** **Monitoring**

**7.1** **Key** **Metrics** **for** **Production** **RAG**

Production systems require comprehensive evaluation.

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

**7.2** **Using** **RAGAS** **for** **Evaluation**

RAGAS provides LLM-based evaluation metrics specifically for RAG
systems.

> from ragas.metrics import ( ContextPrecision, ContextRecall,
> Faithfulness, AnswerRelevancy,
>
> )
>
> from ragas import evaluate from datasets import Dataset
>
> \# Create evaluation dataset eval_data = {
>
> "user_input": \[...\], "reference": \[...\], "retrieved_contexts":
> \[...\], "response": \[...\]
>
> }

\# Questions

\# Ground truth answers

\# Retrieved document chunks

\# Generated answers

> eval_dataset = Dataset.from_dict(eval_data)
>
> \# Evaluate
>
> results = evaluate( eval_dataset, metrics=\[
>
> ContextPrecision(), ContextRecall(), Faithfulness(),
> AnswerRelevancy(),
>
> \]
>
> )

\# % retrieved docs relevant \# % relevant docs retrieved \#
Groundedness of response

\# Does it answer the question?

> print(f"Context Precision: {results\['context_precision'\]}")
> print(f"Context Recall: {results\['context_recall'\]}")
> print(f"Faithfulness: {results\['faithfulness'\]}") print(f"Answer
> Relevancy: {results\['answer_relevancy'\]}")

**7.3** **End-to-End** **Trace** **&** **Monitoring** **with**
**LangFuse**

LangFuse provides production-grade tracing and monitoring.

> from langfuse.callback import CallbackHandler from langfuse import
> Langfuse
>
> \# Initialize langfuse = Langfuse(
>
> public_key="pk\_...", secret_key="sk\_..."
>
> )
>
> \# Instrument agent
>
> callback = CallbackHandler(user_id="user_123")
>
> \# Run with tracing
>
> for chunk in graph.stream(
>
> {"messages": \[{"role": "user", "content": query}\]},
> config={"callbacks": \[callback\]}
>
> ):
>
> process_chunk(chunk)
>
> \# After completion, manually add metrics langfuse.trace(
>
> name="rag_query", input={"query": query}, output={"response":
> response}, metadata={
>
> "model": "gpt-4o", "retrieval_latency_ms": latency, "token_count":
> token_count, "cost_usd": cost,
>
> "hallucination_score": hallucination_score, "groundedness_score":
> groundedness_score,
>
> } )
>
> langfuse.flush() \# Send to server

**Part** **8:** **Production** **Deployment** **Checklist**

**8.1** **Pre-Deployment** **Verification**

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

**8.2** **Scaling** **Considerations**

> \# For production:
>
> \# 1. Use persistent vector store vector_store = Qdrant(
>
> url="grpc://qdrant-server:6334", \# Production cluster
> prefer_grpc=True,
>
> parallel=4 \# Parallel requests )
>
> \# 2. Use persistent checkpointer for HITL
>
> from langgraph.checkpoint.postgres import AsyncPostgresSaver
>
> checkpointer = AsyncPostgresSaver(
> "postgresql://user:pass@db-host:5432/langgraph"
>
> )
>
> \# 3. Configure retries and timeouts
>
> from langchain.chat_models import ChatOpenAI
>
> llm = ChatOpenAI( model="gpt-4o", max_retries=3, timeout=30,
>
> \# Use batching for throughput )
>
> \# 4. Add caching for repeated queries
>
> from langchain.globals import set_llm_cache
>
> from langchain_community.cache import RedisCache import redis
>
> redis_client = redis.Redis.from_url("redis://cache-server:6379")
> set_llm_cache(RedisCache(redis_client=redis_client))
>
> \# 5. Monitor resources import psutil
>
> def check_system_health():
>
> memory_percent = psutil.virtual_memory().percent disk_percent =
> psutil.disk_usage('/').percent
>
> if memory_percent &gt; 85 or disk_percent &gt; 90:
>
> logger.warning(f"System resources low: mem={memory_percent}%,
> disk={disk_percent} \# Trigger cleanup
>
> clear_old_checkpoints()

**Part** **9:** **Advanced** **Techniques** **&** **Optimization**

**9.1** **Query** **Expansion** **for** **Better** **Retrieval**

Generate multiple query variants to increase recall.

> def expand_query(original_query: str) -&gt; list\[str\]: """Generate
> query variants for broader retrieval"""
>
> expansion_prompt = f"""Generate 3-4 variations of this query that
> might retrieve the
>
> Original: "{original_query}"
>
> Variants should:
>
> \- Use different terminology - Expand abbreviations
>
> \- Include related concepts - Use synonyms
>
> Return as newline-separated list."""
>
> response = response_model.invoke(\[{"role": "user", "content":
> expansion_prompt}\]) variants = response.content.strip().split('\n')
>
> \# Return original + variants
>
> return \[original_query\] + \[v.strip() for v in variants\]
>
> \# In retrieval
>
> def retrieve_with_expansion(query: str): queries = expand_query(query)
> all_docs = \[\]
>
> for q in queries:
>
> docs = hybrid_retriever.retrieve_with_reranking(q, top_k=3)
>
> all_docs.extend(docs)
>
> \# Deduplicate and return top results
>
> return list({hash(d.page_content): d for d in
> all_docs}.values())\[:10\]

**9.2** **Long-Context** **Handling**

For long documents, maintain hierarchical context.

> class HierarchicalContextManager:
>
> """Manage context hierarchically to prevent token explosion"""
>
> def \_\_init\_\_(self, max_context_tokens=6000):
> self.max_context_tokens = max_context_tokens
>
> def select_context(self, query, retrieved_docs):
>
> """Select most relevant context sections intelligently"""
>
> \# Start with top chunks selected = \[\] current_tokens = 0
>
> for doc in retrieved_docs:
>
> doc_tokens = num_tokens(doc.page_content)
>
> if current_tokens + doc_tokens &lt;= self.max_context_tokens:
> selected.append(doc)
>
> current_tokens += doc_tokens
>
> elif current_tokens &lt; self.max_context_tokens \* 0.5: \# At least
> get to 50% capacity
>
> \# Truncate this doc to fit truncated_content = doc.page_content\[:
>
> (self.max_context_tokens - current_tokens) \* 4 \# rough chars/token
> \]
>
> doc.page_content = truncated_content selected.append(doc)
>
> break
>
> return selected

**9.3** **Caching** **&** **Performance** **Optimization**

> from langchain_community.cache import RedisCache from
> langchain.globals import set_llm_cache import redis
>
> \# Setup Redis caching
>
> redis_client = redis.Redis.from_url("redis://localhost:6379")
> set_llm_cache(RedisCache(redis_client=redis_client))
>
> \# For retrieval, cache embedding operations class CachedEmbedder:
>
> def \_\_init\_\_(self):
>
> self.embedding_cache = {} self.embedder = OpenAIEmbeddings()
>
> def embed_query(self, query: str):
>
> if query not in self.embedding_cache:
>
> self.embedding_cache\[query\] = self.embedder.embed_query(query)
> return self.embedding_cache\[query\]
>
> \# Batch retrievals when possible
>
> async def batch_retrieve(queries: list\[str\]): """Retrieve for
> multiple queries efficiently""" from concurrent.futures import
> ThreadPoolExecutor
>
> with ThreadPoolExecutor(max_workers=5) as executor: results =
> executor.map(
>
> lambda q: hybrid_retriever.retrieve_with_reranking(q), queries
>
> )
>
> return list(results)

**Conclusion**

Building production-ready agentic RAG systems requires attention to
every layer:

> 1\. **Document** **Processing**: Smart parsing preserving structure
> and metadata
>
> 2\. **Retrieval**: Hybrid search + reranking for precision and recall
>
> 3\. **Context** **Engineering**: Dynamic, adaptive context at each
> agent step
>
> 4\. **Agentic** **Orchestration**: Multi-turn loops with
> decomposition, verification, and reflection
>
> 5\. **Safety**: Layered guardrails and human oversight
>
> 6\. **Evaluation**: Continuous measurement and improvement
>
> 7\. **Performance**: Caching, batching, and resource optimization

The "overkill RAG" described here is not overcomplicated—each component
directly improves reliability, safety, and cost-effectiveness. Start
with the foundations and add complexity only when needed.

**Quick** **Start** **Checklist**

> \[ \] Set up document parsing with metadata attachment
>
> \[ \] Implement hybrid retriever with reranking
>
> \[ \] Build basic LangGraph workflow with retrieval
>
> \[ \] Add document grading and query rewriting
>
> \[ \] Implement fact verification layer
>
> \[ \] Add comprehensive guardrails
>
> \[ \] Set up human-in-the-loop for sensitive operations
>
> \[ \] Integrate RAGAS evaluation metrics
>
> \[ \] Deploy with persistent storage and monitoring
>
> \[ \] Establish baseline metrics and track improvements

**References**

> <u>\[1</u>\] LangChain v1 Documentation.
> [<u>https://docs.langchain.com/oss/python/</u>](https://docs.langchain.com/oss/python/)
>
> <u>\[2</u>\] LangGraph Agentic RAG.
> [<u>https://docs.langchain.com/oss/python/langgraph/agentic-ra</u>g](https://docs.langchain.com/oss/python/langgraph/agentic-rag)
>
> <u>\[3\]</u> Context Engineering Guide.
> [<u>https://docs.langchain.com/oss/python/langchain/context-engineering</u>](https://docs.langchain.com/oss/python/langchain/context-engineering)
> <u>\[4\]</u> Guardrails and Safety.
> [<u>https://docs.langchain.com/oss/python/langchain/guardrails</u>](https://docs.langchain.com/oss/python/langchain/guardrails)
>
> <u>\[5</u>\] Human-in-the-Loop Systems.
> [<u>https://docs.langchain.com/oss/python/langchain/human-in-the-loop</u>](https://docs.langchain.com/oss/python/langchain/human-in-the-loop)
> <u>\[6\]</u> Unstructured Document Processing.
> [<u>https://unstructured.io/</u>](https://unstructured.io/)
>
> <u>\[7\]</u> RAGAS Evaluation Framework.
> [<u>https://docs.ra</u>g<u>as.io/</u>](https://docs.ragas.io/)
> \[<u>8</u>\] LangFuse Production Monitoring.
> [<u>https://lan</u>g<u>fuse.com/</u>](https://langfuse.com/)
>
> <u>\[9\]</u> Prompt Optimization Benchmarking.
> [<u>https://blog.langchain.com/exploring-prompt-optimization/</u>](https://blog.langchain.com/exploring-prompt-optimization/)
>
> <u>\[10</u>\] RAG Chunking Best Practices.
> [<u>https://weaviate.io/blog/chunkin</u>g<u>-strategies-for-ra</u>g](https://weaviate.io/blog/chunking-strategies-for-rag)
> <u>\[11</u>\] <u>\[12</u>\] <u>\[13</u>\] <u>\[14</u>\] <u>\[15</u>\]
> <u>\[16</u>\] <u>\[17</u>\] <u>\[18</u>\] <u>\[19</u>\] <u>\[20</u>\]
> <u>\[21</u>\] <u>\[22</u>\] <u>\[23</u>\] <u>\[24</u>\] <u>\[25</u>\]
> <u>\[26</u>\] <u>\[27</u>\] <u>\[28</u>\] <u>\[29</u>\] <u>\[30</u>\]
> <u>\[31</u>\] \[<u>32</u>\] <u>\[33</u>\] <u>\[34</u>\] <u>\[35</u>\]
> <u>\[36</u>\]

⁂

> 1\.
> [<u>https://docs.langchain.com/oss/python/langgraph/agentic-rag</u>](https://docs.langchain.com/oss/python/langgraph/agentic-rag)
>
> 2\.
> [<u>https://www.datacamp.com/tutorial/lan</u>g<u>chain-v1</u>](https://www.datacamp.com/tutorial/langchain-v1)
>
> 3\.
> [<u>https://www.langchain.com/langgraph</u>](https://www.langchain.com/langgraph)
>
> 4\.
> [<u>https://docs.langchain.com/oss/python/langchain/rag</u>](https://docs.langchain.com/oss/python/langchain/rag)
>
> 5\.
> [<u>https://www.youtube.com/watch?v=AUQJ9eeP-Ls</u>](https://www.youtube.com/watch?v=AUQJ9eeP-Ls)
>
> 6\.
> [<u>https://docs.futureagi.com/cookbook/cookbook5/How-to-build-and-incrementally-improve-RAG-applications-in-L</u>](https://docs.futureagi.com/cookbook/cookbook5/How-to-build-and-incrementally-improve-RAG-applications-in-Langchain)
> [<u>an</u>g<u>chain</u>](https://docs.futureagi.com/cookbook/cookbook5/How-to-build-and-incrementally-improve-RAG-applications-in-Langchain)
>
> 7\.
> [<u>https://www.ibm.com/think/tutorials/build-agentic-workflows-langgraph-granite</u>](https://www.ibm.com/think/tutorials/build-agentic-workflows-langgraph-granite)
>
> 8\.
> [<u>https://blog.langchain.com/exploring-prompt-optimization/</u>](https://blog.langchain.com/exploring-prompt-optimization/)
>
> 9\.
> [<u>https://www.linkedin.com/posts/mahavir-sancheti-7396114_aiagents-llms-artificialintelligence-activity-73772856</u>](https://www.linkedin.com/posts/mahavir-sancheti-7396114_aiagents-llms-artificialintelligence-activity-7377285648057249792-fVSW)
> [<u>48057249792-fVSW</u>](https://www.linkedin.com/posts/mahavir-sancheti-7396114_aiagents-llms-artificialintelligence-activity-7377285648057249792-fVSW)
>
> 10\.
> [<u>https://skywork.ai/blog/ai-agent/langchain-1-0-best-practices-customer-support-knowled</u>g<u>e-base-automation/</u>](https://skywork.ai/blog/ai-agent/langchain-1-0-best-practices-customer-support-knowledge-base-automation/)
>
> 11\.
> [<u>https://www.youtube.com/watch?v=9H7illN79lg</u>](https://www.youtube.com/watch?v=9H7illN79lg)
>
> 12\.
> [<u>https://docs.langchain.com/oss/python/lan</u>g<u>chain/context-engineering</u>](https://docs.langchain.com/oss/python/langchain/context-engineering)
>
> 13\.
> [<u>https://www.youtube.com/watch?v=r5Z\_</u>g<u>YZb4Ns</u>](https://www.youtube.com/watch?v=r5Z_gYZb4Ns)
>
> 14\.
> [<u>https://www.youtube.com/watch?v=Vu8_ANbf3ZA</u>](https://www.youtube.com/watch?v=Vu8_ANbf3ZA)
>
> 15\.
> [<u>https://docs.langchain.com/oss/python/langgraph/workflows-a</u>g<u>ents</u>](https://docs.langchain.com/oss/python/langgraph/workflows-agents)
>
> 16\.
> [<u>https://www.datacamp.com/tutorial/prompt-engineering-with-langchain</u>](https://www.datacamp.com/tutorial/prompt-engineering-with-langchain)
>
> 17\.
> [<u>https://www.reddit.com/r/LangChain/comments/1k662xc/got_grilled_in_an_ml_interview_today_for_my/</u>](https://www.reddit.com/r/LangChain/comments/1k662xc/got_grilled_in_an_ml_interview_today_for_my/)
>
> 18\.
> [<u>https://docs.langchain.com/oss/javascript/lan</u>g<u>chain/overview</u>](https://docs.langchain.com/oss/javascript/langchain/overview)
>
> 19\.
> [<u>https://www.scalablepath.com/machine-learning/langgraph</u>](https://www.scalablepath.com/machine-learning/langgraph)
>
> 20\.
> [<u>https://www.promptingguide.ai/guides/context-engineering-</u>g<u>uide</u>](https://www.promptingguide.ai/guides/context-engineering-guide)

21\.
[<u>https://unstructured.io/blog/chunking-for-ra</u>g<u>-best-practices</u>](https://unstructured.io/blog/chunking-for-rag-best-practices)

22\.
[<u>https://www.linkedin.com/pulse/building-safer-ai-agents-langchain-guardrails-rahul-p-ki7tc</u>](https://www.linkedin.com/pulse/building-safer-ai-agents-langchain-guardrails-rahul-p-ki7tc)

23\.
[<u>https://docs.ragas.io/en/stable/howtos/integrations/\_lang</u>g<u>raph_a</u>g<u>ent_evaluation/</u>](https://docs.ragas.io/en/stable/howtos/integrations/_langgraph_agent_evaluation/)

24\.
[<u>https://docs.databricks.com/aws/en/generative-ai/tutorials/ai-cookbook/quality-data-pipeline-rag</u>](https://docs.databricks.com/aws/en/generative-ai/tutorials/ai-cookbook/quality-data-pipeline-rag)

25\.
[<u>https://hoop.dev/blog/build-faster-prove-control-access-guardrails-for-human-in-the-loop-ai-control-ai-runtime-co</u>](https://hoop.dev/blog/build-faster-prove-control-access-guardrails-for-human-in-the-loop-ai-control-ai-runtime-control/)
[<u>ntrol/</u>](https://hoop.dev/blog/build-faster-prove-control-access-guardrails-for-human-in-the-loop-ai-control-ai-runtime-control/)

26\.
[<u>https://aws.amazon.com/blogs/machine-learning/advanced-tracing-and-evaluation-of-generative-ai-agents-usin</u>](https://aws.amazon.com/blogs/machine-learning/advanced-tracing-and-evaluation-of-generative-ai-agents-using-langchain-and-amazon-sagemaker-ai-mlflow/)
[<u>g-langchain-and-amazon-sagemaker-ai-mlflow/</u>](https://aws.amazon.com/blogs/machine-learning/advanced-tracing-and-evaluation-of-generative-ai-agents-using-langchain-and-amazon-sagemaker-ai-mlflow/)

27\.
[<u>https://weaviate.io/blog/chunking-strategies-for-rag</u>](https://weaviate.io/blog/chunking-strategies-for-rag)

28\.
[<u>https://docs.langchain.com/oss/python/langchain/guardrails</u>](https://docs.langchain.com/oss/python/langchain/guardrails)

29\.
[<u>https://www.elastic.co/search-labs/blog/multi-agent-system-llm-agents-elasticsearch-langgraph</u>](https://www.elastic.co/search-labs/blog/multi-agent-system-llm-agents-elasticsearch-langgraph)

30\.
[<u>https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/rag/rag-chunking-phase</u>](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/rag/rag-chunking-phase)

31\.
[<u>https://docs.langchain.com/oss/python/langchain/human-in-the-loop</u>](https://docs.langchain.com/oss/python/langchain/human-in-the-loop)

32\.
[<u>https://langfuse.com/guides/cookbook/example_langgraph_a</u>g<u>ents</u>](https://langfuse.com/guides/cookbook/example_langgraph_agents)

33\.
[<u>https://docs.langchain.com/oss/python/lan</u>g<u>chain/human-in-the-loop</u>](https://docs.langchain.com/oss/python/langchain/human-in-the-loop)

34\.
[<u>https://docs.langchain.com/oss/python/langchain/guardrails</u>](https://docs.langchain.com/oss/python/langchain/guardrails)

35\.
[<u>https://docs.langchain.com/oss/python/langgraph/agentic-rag</u>](https://docs.langchain.com/oss/python/langgraph/agentic-rag)

36\.
[<u>https://docs.langchain.com/oss/python/langchain/context-engineering</u>](https://docs.langchain.com/oss/python/langchain/context-engineering)
