# FoundryIQ Demo — VNET-Integrated Azure AI Foundry

Private-network Azure AI Foundry demo with agentic retrieval, AI Search, Blob Storage, and a jump-host accessible via Azure Bastion. All services use **Entra ID authentication** and **private endpoints** — no API keys.

## Architecture

```
┌──────────────────────────────── rg-foundryiq-demo-sc ──────────────────────────────────┐
│                                                                                        │
│  ┌──── vnet-foundryiq-demo-sc (10.0.0.0/16) ──────────────────────────────────────┐    │
│  │                                                                                │    │
│  │  snet-workload (10.0.1.0/24)       snet-private-endpoints (10.0.2.0/24)        │    │
│  │  ┌───────────────────────┐         ┌──────────────────────────────────┐        │    │
│  │  │ vm-foundryiq-jump     │         │ pe-ais-foundryiq  (AI Services)  │        │    │
│  │  │ Ubuntu 24.04 + xrdp   │◄───────►│ pe-st-foundryiq   (Doc Storage)  │        │    │
│  │  │ Firefox + Azure CLI   │         │ pe-st-agent       (Agent Storage)│        │    │
│  │  └───────────┬───────────┘         │ pe-srch-foundryiq (AI Search)    │        │    │
│  │              │                     │ pe-cosmos-foundryiq (Cosmos DB)  │        │    │
│  │  ┌───────────┴──────┐              └──────────────────────────────────┘        │    │
│  │  │ ng-foundryiq-*   │                                                          │    │
│  │  │ NAT Gateway      │              snet-agent (10.0.4.0/24)                    │    │
│  │  │ (outbound)       │              ┌──────────────────────────┐                │    │
│  │  └──────────────────┘              │ Foundry Agent Service    │                │    │
│  │                                    │ (VNET-injected via       │                │    │
│  │  AzureBastionSubnet (10.0.3.0/26)  │  Microsoft.App delegate) │                │    │
│  │  ┌──────────────────────────┐      └──────────────────────────┘                │    │
│  │  │ bas-foundryiq-demo-sc    │◄── SSH / RDP tunnel                              │    │
│  │  │ Standard SKU + tunneling │                                                  │    │
│  │  └──────────────────────────┘                                                  │    │
│  └────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                        │
│  AI Services (Foundry)         AI Search                  Document Storage             │
│  ais-foundryiq-XXXXX           srch-foundryiq-XXXXX       stfoundryiqXXXXX             │
│  ├─ gpt-4.1     (100 TPM)     ├─ knowledge-base-index    ├─ knowledge-base container   │
│  ├─ gpt-5.4     (100 TPM)     ├─ Knowledge Source         └─ 4 sample PDFs              │
│  ├─ text-embedding-3-large    ├─ Knowledge Base (MCP)                                   │
│  ├─ prj-foundryiq-demo        ├─ Shared PL → Storage     Agent Storage                 │
│  └─ Capability Hosts          └─ Shared PL → AI Services  stagentXXXXX (bypass Azure)  │
│     ├─ CosmosDB connection                                                              │
│     ├─ Search connection       Cosmos DB                                                │
│     └─ Storage connection      cosmos-foundryiq-XXXXX (agent thread storage)            │
│                                                                                        │
│  Private DNS: cognitiveservices · openai · services.ai · blob · search · documents     │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

## What's Deployed

| Resource | Name Pattern | Notes |
|---|---|---|
| Resource Group | `rg-foundryiq-demo-sc` | Sweden Central, tag `SecurityControl=ignore` |
| VNET | `vnet-foundryiq-demo-sc` | `10.0.0.0/16`, 4 subnets |
| NAT Gateway | `ng-foundryiq-demo-sc` | Outbound for workload subnet |
| AI Services | `ais-foundryiq-{suffix}` | S0, `publicNetworkAccess=Disabled`, `networkAcls.defaultAction=Allow` |
| Foundry Project | `prj-foundryiq-demo` | Agent hosting, MCP connections |
| Models | `gpt-41` / `gpt-54` | GlobalStandard, capacity 100 each |
| Embedding | `text-embedding-3-large` | Standard, capacity 50 |
| Doc Storage | `stfoundryiq{suffix}` | Fully private — `public_network_access=false`, shared keys disabled |
| Agent Storage | `stagent{suffix}` | `Deny` + `bypass=AzureServices` (required by Agent Service platform) |
| AI Search | `srch-foundryiq-{suffix}` | Standard, semantic search, `local_auth=false` (Entra only) |
| Cosmos DB | `cosmos-foundryiq-{suffix}` | Agent thread storage, `local_auth=disabled`, private endpoint |
| Bastion | `bas-foundryiq-demo-sc` | Standard SKU, tunneling + IP connect |
| Jump VM | `vm-foundryiq-jump` | D2s_v5, Ubuntu 24.04, xrdp + Firefox |
| Private Endpoints | 5 PEs | AI Services, Doc Storage, Agent Storage, Search, Cosmos DB |
| Private DNS Zones | 6 zones | cognitiveservices, openai, services.ai, blob, search, documents |
| Capability Hosts | Account + Project | VNET-injected agent infrastructure |
| Delegated Subnet | `snet-agent` (10.0.4.0/24) | `Microsoft.App/environments` delegation |

## Security Model

| Control | Implementation |
|---|---|
| Network isolation | All services behind private endpoints; private DNS zones for resolution |
| Foundry | `publicNetworkAccess=Disabled` + `networkAcls.defaultAction=Allow` (per [reference template](https://github.com/azure-ai-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-terraform/15b-private-network-standard-agent-setup-byovnet)) |
| Document Storage | Fully private: `public_network_access_enabled=false`, `shared_access_key_enabled=false` |
| Agent Storage | `default_action=Deny`, `bypass=AzureServices` (Agent Service platform needs to provision containers) |
| AI Search | `public_network_access=false` for data plane, `local_authentication_enabled=false` (Entra only) |
| Cosmos DB | `local_authentication_disabled=true` (Entra only), private endpoint |
| Auth everywhere | Entra ID managed identities + RBAC. Zero API keys. |
| VNET injection | Agent Service containers injected into delegated subnet for private networking |

**RBAC assignments (30+ roles across 6 identities):**

| Identity | Key Roles |
|---|---|
| Current user | Storage Blob Data Contributor, Cognitive Services OpenAI/Contributor, Search Service/Index Data Contributor |
| AI Search MI | Storage Blob Data Reader, Cognitive Services User |
| Foundry MI | Storage Blob Data Contributor, Search Index Data Reader, Cosmos DB Operator |
| Project MI | OpenAI User, Storage Blob Data Contributor, Search Index Data Contributor, Cosmos DB Operator |
| Jump VM MI | Owner (RG), full data-plane access to all services |

## Quick Start

### 1. Deploy Infrastructure

```bash
cd terraform/
cat > terraform.tfvars <<EOF
subscription_id   = "<your-subscription-id>"
vm_admin_password = "<strong-password>"
EOF
terraform init && terraform apply
```

### 2. Generate & Upload Sample PDFs

```bash
python scripts/generate_pdfs.py
# Temporarily allow your IP on doc storage, upload, then remove:
az storage account network-rule add --account-name <name> -g rg-foundryiq-demo-sc --ip-address <your-ip>
python scripts/setup_search.py
az storage account network-rule remove --account-name <name> -g rg-foundryiq-demo-sc --ip-address <your-ip>
```

### 3. Setup Knowledge Base & Test (from Jump VM via Bastion)

```bash
# SSH to jump VM
az network bastion ssh --name bas-foundryiq-demo-sc -g rg-foundryiq-demo-sc \
  --target-resource-id <vm-resource-id> --auth-type ssh-key --username azureuser \
  --ssh-key ~/.ssh/foundryiq-jump.pem

# On the VM:
source ~/foundryiq-env.sh
/opt/foundryiq-env/bin/python ~/setup_knowledgebase.py   # Knowledge source + base + MCP agent
/opt/foundryiq-env/bin/python ~/test_agent.py            # Direct chat + grounded search
```

### RDP Tunnel (xrdp)

```bash
az network bastion tunnel --name bas-foundryiq-demo-sc -g rg-foundryiq-demo-sc \
  --target-resource-id <vm-resource-id> --resource-port 3389 --port 53389
# RDP to localhost:53389
```

Save SSH key: `terraform -chdir=terraform output -raw ssh_private_key > ~/.ssh/foundryiq-jump.pem`

## File Structure

```
terraform/
├── main.tf                # Providers, resource group, random suffix
├── variables.tf           # subscription_id, vm_admin_password
├── network.tf             # VNET, 4 subnets (workload, PE, bastion, agent), NAT, NSG
├── dns.tf                 # 6 private DNS zones + VNET links
├── storage.tf             # Document storage (fully private) + Agent storage (bypass)
├── foundry.tf             # AI Services + Foundry project
├── models.tf              # gpt-4.1, gpt-5.4, text-embedding-3-large
├── search.tf              # AI Search + shared private links + approval scripts
├── cosmosdb.tf            # Cosmos DB + RBAC for agent thread storage
├── private_endpoints.tf   # PEs for AI Services, Doc Storage, Search
├── connections.tf         # Project-level connections (Search, Storage, CosmosDB)
├── agent_infra.tf         # VNET injection + capability hosts (account + project)
├── rbac.tf                # 30+ role assignments across 6 identities
├── bastion.tf             # Bastion + jump VM + SSH key + cloud-init
├── cloud-init.yaml        # VM bootstrap: xrdp, Firefox, CLI, Python, env vars
└── outputs.tf             # Endpoints, names, SSH key, IPs
scripts/
├── generate_pdfs.py       # Generate 4 Contoso policy PDFs
├── setup_search.py        # Upload PDFs, create index + indexer
├── setup_knowledgebase.py # Knowledge source + base + MCP agent
└── test_agent.py          # Direct chat + grounded search (On Your Data)
sample-data/               # Generated PDFs (IT Security, Employee Handbook, Cloud Arch, DR Plan)
```

## Network Design Decisions

| Decision | Rationale | Source |
|---|---|---|
| Foundry `networkAcls.defaultAction=Allow` | With `publicNetworkAccess=Disabled`, this allows Azure internal platform communication (NOT public internet). Required for Agent Service control plane. | [Official template](https://github.com/azure-ai-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-terraform/15b-private-network-standard-agent-setup-byovnet) |
| Agent Storage `bypass=AzureServices` | Agent Service platform (Azure trusted service) must provision containers. Only for agent data storage, NOT document storage. | [Reference template](https://github.com/azure-ai-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-terraform/15b-private-network-standard-agent-setup-byovnet) |
| Document Storage fully private | `public_network_access_enabled=false`, no bypass. Accessed only via PE + shared private links. | Security best practice |
| Two storage accounts | Separation of concerns: doc storage (zero bypass) vs agent storage (platform bypass required). | Design decision |

## Known Limitations

1. **Foundry resource uses AzAPI** — The `networkInjections` property must be set at creation time (not added later) for the Container Apps environment to properly bootstrap in the VNET. This demo uses `azapi_resource` for the Foundry resource, matching the [official reference template](https://github.com/azure-ai-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-terraform/15b-private-network-standard-agent-setup-byovnet).

2. **Cosmos DB public access** — Set to `true` with `local_auth=disabled` (Entra only) because the Foundry Agent Service control plane accesses Cosmos DB from managed infrastructure. With a fresh `azapi_resource` creation (including `networkInjections`), the control plane should route through the VNET — try setting `public_network_access_enabled=false` after verifying agent creation works.
