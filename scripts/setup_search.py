#!/usr/bin/env python3
"""
Setup AI Search index, data source, and indexer for the FoundryIQ knowledge base.
Uploads sample PDFs to blob storage and configures AI Search to index them.

Usage: python setup_search.py
Requires environment variables (set by Terraform outputs):
  FOUNDRY_ENDPOINT, SEARCH_ENDPOINT, STORAGE_ACCOUNT, SUBSCRIPTION_ID, RESOURCE_GROUP
"""
import os, sys, json, time, glob

def ensure_packages():
    packages = ["azure-identity", "azure-search-documents", "azure-storage-blob"]
    for pkg in packages:
        try:
            __import__(pkg.replace("-", "_").replace("azure_", "azure."))
        except ImportError:
            os.system(f"{sys.executable} -m pip install {pkg} --quiet")

ensure_packages()

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (
    SearchIndex,
    SearchField,
    SearchFieldDataType,
    SimpleField,
    SearchableField,
    SemanticConfiguration,
    SemanticSearch,
    SemanticPrioritizedFields,
    SemanticField,
)

def upload_pdfs(credential):
    """Upload sample PDFs to blob storage."""
    print("\n=== Uploading PDFs to Blob Storage ===")
    storage_account = os.environ["STORAGE_ACCOUNT"]
    blob_url = f"https://{storage_account}.blob.core.windows.net"
    blob_client = BlobServiceClient(account_url=blob_url, credential=credential)
    container = blob_client.get_container_client("knowledge-base")

    pdf_dir = os.path.join(os.path.dirname(__file__), "..", "sample-data")
    if not os.path.exists(pdf_dir):
        print(f"  ERROR: Sample data directory not found: {pdf_dir}")
        print("  Run generate_pdfs.py first!")
        return False

    pdf_files = glob.glob(os.path.join(pdf_dir, "*.pdf"))
    if not pdf_files:
        print("  ERROR: No PDF files found in sample-data/")
        return False

    for pdf_path in pdf_files:
        blob_name = os.path.basename(pdf_path)
        print(f"  Uploading: {blob_name}")
        with open(pdf_path, "rb") as f:
            container.upload_blob(name=blob_name, data=f, overwrite=True)

    print(f"  Uploaded {len(pdf_files)} files successfully")
    return True

def create_index(credential):
    """Create AI Search index."""
    print("\n=== Creating AI Search Index ===")
    search_endpoint = os.environ["SEARCH_ENDPOINT"]
    index_client = SearchIndexClient(endpoint=search_endpoint, credential=credential)

    index_name = "knowledge-base-index"

    fields = [
        SimpleField(name="id", type=SearchFieldDataType.String, key=True, filterable=True),
        SearchableField(name="content", type=SearchFieldDataType.String, analyzer_name="en.microsoft"),
        SimpleField(name="metadata_storage_path", type=SearchFieldDataType.String, filterable=True),
        SimpleField(name="metadata_storage_name", type=SearchFieldDataType.String, filterable=True, sortable=True),
        SimpleField(name="metadata_storage_content_type", type=SearchFieldDataType.String, filterable=True),
        SimpleField(name="metadata_storage_size", type=SearchFieldDataType.Int64, filterable=True),
        SimpleField(name="metadata_storage_last_modified", type=SearchFieldDataType.DateTimeOffset, filterable=True, sortable=True),
    ]

    semantic_config = SemanticConfiguration(
        name="default",
        prioritized_fields=SemanticPrioritizedFields(
            content_fields=[SemanticField(field_name="content")],
            title_fields=[SemanticField(field_name="metadata_storage_name")],
        ),
    )

    index = SearchIndex(
        name=index_name,
        fields=fields,
        semantic_search=SemanticSearch(configurations=[semantic_config]),
    )

    try:
        index_client.delete_index(index_name)
        print(f"  Deleted existing index: {index_name}")
    except Exception:
        pass

    index_client.create_index(index)
    print(f"  Created index: {index_name}")
    return index_name

def create_datasource_and_indexer(credential):
    """Create data source and indexer using REST API (SDK may not cover all features)."""
    import requests
    print("\n=== Creating Data Source & Indexer ===")

    search_endpoint = os.environ["SEARCH_ENDPOINT"].rstrip("/")
    storage_account = os.environ["STORAGE_ACCOUNT"]
    resource_id = f"/subscriptions/{os.environ['SUBSCRIPTION_ID']}/resourceGroups/{os.environ['RESOURCE_GROUP']}/providers/Microsoft.Storage/storageAccounts/{storage_account}"
    api_version = "2024-07-01"

    token = credential.get_token("https://search.azure.com/.default")
    headers = {
        "Authorization": f"Bearer {token.token}",
        "Content-Type": "application/json",
    }

    # Create data source
    ds_name = "knowledge-base-ds"
    ds_body = {
        "name": ds_name,
        "type": "azureblob",
        "credentials": {"connectionString": f"ResourceId={resource_id};"},
        "container": {"name": "knowledge-base"},
        "dataDeletionDetectionPolicy": {"@odata.type": "#Microsoft.Azure.Search.NativeBlobSoftDeleteDeletionDetectionPolicy"},
    }
    resp = requests.put(f"{search_endpoint}/datasources('{ds_name}')?api-version={api_version}", headers=headers, json=ds_body)
    if resp.status_code in (200, 201):
        print(f"  Created data source: {ds_name}")
    else:
        print(f"  Data source error ({resp.status_code}): {resp.text}")
        return None

    # Create indexer
    indexer_name = "knowledge-base-indexer"
    indexer_body = {
        "name": indexer_name,
        "dataSourceName": ds_name,
        "targetIndexName": "knowledge-base-index",
        "parameters": {
            "configuration": {
                "parsingMode": "default",
                "dataToExtract": "contentAndMetadata",
            }
        },
        "schedule": None,
    }
    resp = requests.put(f"{search_endpoint}/indexers('{indexer_name}')?api-version={api_version}", headers=headers, json=indexer_body)
    if resp.status_code in (200, 201):
        print(f"  Created indexer: {indexer_name}")
    else:
        print(f"  Indexer error ({resp.status_code}): {resp.text}")
        return None

    # Run the indexer
    resp = requests.post(f"{search_endpoint}/indexers('{indexer_name}')/search.run?api-version={api_version}", headers=headers)
    if resp.status_code in (202, 204):
        print(f"  Indexer run triggered")
    else:
        print(f"  Indexer run error ({resp.status_code}): {resp.text}")

    # Wait for indexer to complete
    print("  Waiting for indexer to complete...")
    for i in range(30):
        time.sleep(10)
        resp = requests.get(f"{search_endpoint}/indexers('{indexer_name}')/search.status?api-version={api_version}", headers=headers)
        if resp.status_code == 200:
            status = resp.json()
            last_result = status.get("lastResult", {})
            exec_status = last_result.get("status", "unknown")
            if exec_status == "success":
                doc_count = last_result.get("itemsProcessed", 0)
                print(f"  Indexer completed: {doc_count} documents processed")
                return indexer_name
            elif exec_status in ("transientFailure", "persistentFailure"):
                print(f"  Indexer failed: {last_result.get('errorMessage', 'unknown error')}")
                return None
            print(f"  Status: {exec_status} (attempt {i+1}/30)")
    
    print("  WARNING: Indexer did not complete in time")
    return indexer_name

def main():
    print("=" * 60)
    print("FoundryIQ - AI Search Setup")
    print("=" * 60)

    required_vars = ["SEARCH_ENDPOINT", "STORAGE_ACCOUNT", "SUBSCRIPTION_ID", "RESOURCE_GROUP"]
    missing = [v for v in required_vars if not os.environ.get(v)]
    if missing:
        print(f"ERROR: Missing environment variables: {', '.join(missing)}")
        print("Set them from Terraform outputs or source foundryiq-env.sh")
        sys.exit(1)

    credential = DefaultAzureCredential()

    if upload_pdfs(credential):
        index_name = create_index(credential)
        create_datasource_and_indexer(credential)

    print("\n" + "=" * 60)
    print("Setup complete!")
    print("=" * 60)

if __name__ == "__main__":
    main()
