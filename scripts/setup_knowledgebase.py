#!/usr/bin/env python3
"""
FoundryIQ: Setup agentic retrieval knowledge base and Foundry Agent.
Creates knowledge source, knowledge base (MCP), project connection, and agent.
Run from the jump VM after sourcing foundryiq-env.sh.
"""
import os, sys, json, time, requests

# Ensure correct packages
try:
    from azure.identity import DefaultAzureCredential, ManagedIdentityCredential, get_bearer_token_provider
    from azure.search.documents.indexes import SearchIndexClient
    from azure.search.documents.indexes.models import (
        SearchIndex, SearchField, SearchFieldDataType,
        SimpleField, SearchableField,
        SemanticConfiguration, SemanticSearch, SemanticPrioritizedFields, SemanticField,
        VectorSearch, VectorSearchProfile, HnswAlgorithmConfiguration,
        AzureOpenAIVectorizer, AzureOpenAIVectorizerParameters,
        SearchIndexKnowledgeSource, SearchIndexKnowledgeSourceParameters, SearchIndexFieldReference,
        KnowledgeBase, KnowledgeSourceReference,
        KnowledgeRetrievalMinimalReasoningEffort, KnowledgeRetrievalOutputMode,
    )
    from azure.search.documents import SearchClient
    from azure.ai.projects import AIProjectClient
    from azure.ai.projects.models import PromptAgentDefinition, MCPTool
except ImportError as e:
    print(f"Missing package: {e}")
    print("Run: /opt/foundryiq-env/bin/pip install azure-search-documents==11.7.0b2 azure-ai-projects==2.0.0b1")
    sys.exit(1)


def main():
    print("=" * 60)
    print("FoundryIQ - Agentic Retrieval Knowledge Base Setup")
    print("=" * 60)

    # Load environment
    search_endpoint = os.environ["SEARCH_ENDPOINT"]
    foundry_endpoint = os.environ["FOUNDRY_ENDPOINT"]
    foundry_name = os.environ["FOUNDRY_NAME"]
    project_name = os.environ["PROJECT_NAME"]
    subscription_id = os.environ["SUBSCRIPTION_ID"]
    resource_group = os.environ["RESOURCE_GROUP"]
    gpt41_deployment = os.environ.get("GPT41_DEPLOYMENT", "gpt-41")

    project_resource_id = f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.CognitiveServices/accounts/{foundry_name}/projects/{project_name}"
    project_endpoint = f"https://{foundry_name}.services.ai.azure.com/api/projects/{project_name}"
    openai_endpoint = f"https://{foundry_name}.openai.azure.com"
    embedding_deployment = "text-embedding-3-large"

    credential = DefaultAzureCredential()
    index_client = SearchIndexClient(endpoint=search_endpoint, credential=credential)

    index_name = "knowledge-base-index"
    knowledge_source_name = "contoso-knowledge-source"
    knowledge_base_name = "contoso-knowledge-base"
    connection_name = "kb-mcp-connection"
    agent_name = "contoso-knowledge-agent"

    # ---- Step 1: Update search index with vector search ----
    print("\n=== Step 1: Creating search index with vector support ===")

    index = SearchIndex(
        name=index_name,
        fields=[
            SimpleField(name="id", type=SearchFieldDataType.String, key=True, filterable=True),
            SearchableField(name="content", type=SearchFieldDataType.String, analyzer_name="en.microsoft"),
            SimpleField(name="metadata_storage_path", type=SearchFieldDataType.String, filterable=True),
            SimpleField(name="metadata_storage_name", type=SearchFieldDataType.String, filterable=True, sortable=True),
            SimpleField(name="metadata_storage_content_type", type=SearchFieldDataType.String, filterable=True),
            SimpleField(name="metadata_storage_size", type=SearchFieldDataType.Int64, filterable=True),
            SimpleField(name="metadata_storage_last_modified", type=SearchFieldDataType.DateTimeOffset, filterable=True, sortable=True),
        ],
        vector_search=VectorSearch(
            profiles=[VectorSearchProfile(name="vec_profile", algorithm_configuration_name="hnsw_alg", vectorizer_name="openai_vectorizer")],
            algorithms=[HnswAlgorithmConfiguration(name="hnsw_alg")],
            vectorizers=[
                AzureOpenAIVectorizer(
                    vectorizer_name="openai_vectorizer",
                    parameters=AzureOpenAIVectorizerParameters(
                        resource_url=openai_endpoint,
                        deployment_name=embedding_deployment,
                        model_name=embedding_deployment,
                    ),
                )
            ],
        ),
        semantic_search=SemanticSearch(
            default_configuration_name="default",
            configurations=[
                SemanticConfiguration(
                    name="default",
                    prioritized_fields=SemanticPrioritizedFields(
                        content_fields=[SemanticField(field_name="content")],
                    ),
                )
            ],
        ),
    )

    index_client.create_or_update_index(index)
    print(f"  Index '{index_name}' created/updated with vector search support")

    # ---- Step 2: Re-run indexer to populate ----
    print("\n=== Step 2: Running indexer ===")
    token = credential.get_token("https://search.azure.com/.default")
    headers = {"Authorization": f"Bearer {token.token}", "Content-Type": "application/json"}

    # Reset and run
    requests.post(f"{search_endpoint}/indexers('knowledge-base-indexer')/search.reset?api-version=2024-07-01", headers=headers)
    time.sleep(3)
    requests.post(f"{search_endpoint}/indexers('knowledge-base-indexer')/search.run?api-version=2024-07-01", headers=headers)
    print("  Indexer triggered, waiting for completion...")

    for i in range(30):
        time.sleep(10)
        resp = requests.get(f"{search_endpoint}/indexers('knowledge-base-indexer')/search.status?api-version=2024-07-01", headers=headers)
        if resp.status_code == 200:
            last = resp.json().get("lastResult", {})
            if last.get("status") == "success":
                print(f"  Indexer complete: {last.get('itemsProcessed', 0)} documents")
                break
            elif last.get("status") in ("transientFailure", "persistentFailure"):
                print(f"  Indexer failed: {last.get('errorMessage')}")
                break
    else:
        print("  WARNING: Indexer did not complete in time, continuing...")

    # ---- Step 3: Create knowledge source ----
    print("\n=== Step 3: Creating knowledge source ===")

    ks = SearchIndexKnowledgeSource(
        name=knowledge_source_name,
        description="Contoso Corp policy and standards documents knowledge source",
        search_index_parameters=SearchIndexKnowledgeSourceParameters(
            search_index_name=index_name,
            semantic_configuration_name="default",
            source_data_fields=[
                SearchIndexFieldReference(name="metadata_storage_name"),
            ],
        ),
    )

    index_client.create_or_update_knowledge_source(knowledge_source=ks)
    print(f"  Knowledge source '{knowledge_source_name}' created")

    # ---- Step 4: Create knowledge base ----
    print("\n=== Step 4: Creating knowledge base ===")

    kb = KnowledgeBase(
        name=knowledge_base_name,
        knowledge_sources=[
            KnowledgeSourceReference(name=knowledge_source_name),
        ],
        output_mode=KnowledgeRetrievalOutputMode.EXTRACTIVE_DATA,
        retrieval_reasoning_effort=KnowledgeRetrievalMinimalReasoningEffort(),
    )

    index_client.create_or_update_knowledge_base(knowledge_base=kb)
    mcp_endpoint = f"{search_endpoint}/knowledgebases/{knowledge_base_name}/mcp?api-version=2025-11-01-Preview"
    print(f"  Knowledge base '{knowledge_base_name}' created")
    print(f"  MCP endpoint: {mcp_endpoint}")

    # ---- Step 5: Create project connection to MCP endpoint ----
    print("\n=== Step 5: Creating project connection ===")

    bearer = get_bearer_token_provider(credential, "https://management.azure.com/.default")
    conn_headers = {"Authorization": f"Bearer {bearer()}", "Content-Type": "application/json"}

    conn_body = {
        "name": connection_name,
        "type": "Microsoft.MachineLearningServices/workspaces/connections",
        "properties": {
            "authType": "ProjectManagedIdentity",
            "category": "RemoteTool",
            "target": mcp_endpoint,
            "isSharedToAll": True,
            "audience": "https://search.azure.com/",
            "metadata": {"ApiType": "Azure"},
        },
    }

    resp = requests.put(
        f"https://management.azure.com{project_resource_id}/connections/{connection_name}?api-version=2025-10-01-preview",
        headers=conn_headers,
        json=conn_body,
    )
    if resp.status_code in (200, 201):
        print(f"  Project connection '{connection_name}' created")
    else:
        print(f"  Connection error ({resp.status_code}): {resp.text[:300]}")

    # ---- Step 6: Create agent with MCP tool ----
    print("\n=== Step 6: Creating Foundry Agent ===")

    project_client = AIProjectClient(endpoint=project_endpoint, credential=credential)

    instructions = """
You are a helpful Contoso Corp knowledge assistant. You MUST use the knowledge base tool to answer all questions.
Never answer from your own knowledge. Always ground your responses in the retrieved documents.
Provide annotations for citations using the MCP knowledge base tool.
If you cannot find the answer in the knowledge base, respond with "I don't have that information in the knowledge base."
"""

    mcp_kb_tool = MCPTool(
        server_label="knowledge-base",
        server_url=mcp_endpoint,
        require_approval="never",
        allowed_tools=["knowledge_base_retrieve"],
        project_connection_id=connection_name,
    )

    agent = project_client.agents.create_version(
        agent_name=agent_name,
        definition=PromptAgentDefinition(
            model=gpt41_deployment,
            instructions=instructions,
            tools=[mcp_kb_tool],
        ),
    )
    print(f"  Agent '{agent_name}' created successfully")

    # ---- Step 7: Test the agent ----
    print("\n=== Step 7: Testing Agent ===")

    openai_client = project_client.get_openai_client()
    conversation = openai_client.conversations.create()

    test_questions = [
        "What is the password policy at Contoso Corp? How long must passwords be and how often must they be changed?",
        "What are the RTO and RPO for Tier-1 mission critical services?",
        "Does Contoso allow personal devices to access corporate data?",
    ]

    for i, question in enumerate(test_questions, 1):
        print(f"\n  Q{i}: {question}")
        try:
            response = openai_client.responses.create(
                conversation=conversation.id,
                tool_choice="required",
                input=question,
                extra_body={"agent": {"name": agent.name, "type": "agent_reference"}},
            )
            answer = response.output_text
            print(f"  A{i}: {answer[:400]}{'...' if len(answer) > 400 else ''}")
        except Exception as e:
            print(f"  A{i}: ERROR - {e}")

    print("\n" + "=" * 60)
    print("Agentic retrieval setup complete!")
    print(f"  Knowledge Base MCP: {mcp_endpoint}")
    print(f"  Project Endpoint: {project_endpoint}")
    print(f"  Agent: {agent_name}")
    print("=" * 60)


if __name__ == "__main__":
    main()
