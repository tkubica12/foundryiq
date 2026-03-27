#!/usr/bin/env python3
"""
Create and test a Foundry Agent with Azure AI Search knowledge base.

Usage: python test_agent.py
Requires environment variables (set by Terraform outputs or foundryiq-env.sh):
  FOUNDRY_ENDPOINT, SEARCH_ENDPOINT, GPT41_DEPLOYMENT, SUBSCRIPTION_ID, RESOURCE_GROUP, FOUNDRY_NAME, PROJECT_NAME
"""
import os, sys, json, time

def ensure_packages():
    packages = ["azure-identity", "azure-ai-projects", "openai"]
    for pkg in packages:
        try:
            __import__(pkg.replace("-", "_").replace("azure_", "azure."))
        except ImportError:
            os.system(f"{sys.executable} -m pip install {pkg} --quiet")

ensure_packages()

from azure.identity import DefaultAzureCredential
from openai import AzureOpenAI


def test_chat_with_search():
    """Test the model with grounded search using the data in AI Search."""
    print("\n=== Testing Chat with AI Search Grounding ===")
    credential = DefaultAzureCredential()
    token = credential.get_token("https://cognitiveservices.azure.com/.default")

    client = AzureOpenAI(
        azure_endpoint=os.environ["FOUNDRY_ENDPOINT"],
        api_version="2025-01-01-preview",
        azure_ad_token=token.token,
    )

    search_endpoint = os.environ["SEARCH_ENDPOINT"]
    deployment = os.environ["GPT41_DEPLOYMENT"]

    # Questions about the knowledge base content
    questions = [
        "What is the password policy at Contoso Corp? How long must passwords be?",
        "What are the RTO and RPO for Tier-1 services in the disaster recovery plan?",
        "How many days of annual leave do employees get at Contoso?",
        "What cloud provider does Contoso use as primary and what IaC tools are required?",
    ]

    for i, question in enumerate(questions, 1):
        print(f"\n  Q{i}: {question}")
        try:
            response = client.chat.completions.create(
                model=deployment,
                messages=[
                    {"role": "system", "content": "You are a helpful assistant that answers questions based on the company knowledge base. Be specific and cite details from the documents."},
                    {"role": "user", "content": question},
                ],
                extra_body={
                    "data_sources": [
                        {
                            "type": "azure_search",
                            "parameters": {
                                "endpoint": search_endpoint,
                                "index_name": "knowledge-base-index",
                                "authentication": {
                                    "type": "system_assigned_managed_identity",
                                },
                                "query_type": "semantic",
                                "semantic_configuration": "default",
                                "top_n_documents": 3,
                            },
                        }
                    ]
                },
                max_tokens=300,
            )
            answer = response.choices[0].message.content.strip()
            print(f"  A{i}: {answer[:300]}{'...' if len(answer) > 300 else ''}")
            print(f"  Status: PASS")
        except Exception as e:
            print(f"  Status: FAIL - {e}")


def test_direct_chat():
    """Test direct chat without search grounding."""
    print("\n=== Testing Direct Chat ===")
    credential = DefaultAzureCredential()
    token = credential.get_token("https://cognitiveservices.azure.com/.default")

    client = AzureOpenAI(
        azure_endpoint=os.environ["FOUNDRY_ENDPOINT"],
        api_version="2025-01-01-preview",
        azure_ad_token=token.token,
    )

    for deployment_name in [os.environ.get("GPT41_DEPLOYMENT", "gpt-41"), os.environ.get("GPT54_DEPLOYMENT", "gpt-54")]:
        print(f"\n  Testing deployment: {deployment_name}")
        try:
            response = client.chat.completions.create(
                model=deployment_name,
                messages=[
                    {"role": "user", "content": "What is 2+2? Answer in one word."},
                ],
                max_tokens=10,
            )
            answer = response.choices[0].message.content.strip()
            print(f"  Response: {answer}")
            print(f"  Status: PASS")
        except Exception as e:
            print(f"  Status: FAIL - {e}")


def main():
    print("=" * 60)
    print("FoundryIQ - Agent & Knowledge Base Test")
    print("=" * 60)

    required_vars = ["FOUNDRY_ENDPOINT", "SEARCH_ENDPOINT", "GPT41_DEPLOYMENT"]
    missing = [v for v in required_vars if not os.environ.get(v)]
    if missing:
        print(f"ERROR: Missing environment variables: {', '.join(missing)}")
        print("Set them from Terraform outputs or source foundryiq-env.sh")
        sys.exit(1)

    test_direct_chat()
    test_chat_with_search()

    print("\n" + "=" * 60)
    print("All tests complete!")
    print("=" * 60)

if __name__ == "__main__":
    main()
