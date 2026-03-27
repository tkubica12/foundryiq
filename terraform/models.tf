# GPT-4.1 deployment
resource "azurerm_cognitive_deployment" "gpt41" {
  name                 = "gpt-41"
  cognitive_account_id = local.foundry_id

  model {
    format  = "OpenAI"
    name    = "gpt-4.1"
    version = "2025-04-14"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 100
  }
}

# GPT-5.4 deployment
resource "azurerm_cognitive_deployment" "gpt54" {
  name                 = "gpt-54"
  cognitive_account_id = local.foundry_id

  model {
    format  = "OpenAI"
    name    = "gpt-5.4"
    version = "2026-03-05"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 100
  }

  depends_on = [azurerm_cognitive_deployment.gpt41]
}

# text-embedding-3-large for agentic retrieval vectorization
resource "azurerm_cognitive_deployment" "embedding" {
  name                 = "text-embedding-3-large"
  cognitive_account_id = local.foundry_id

  model {
    format  = "OpenAI"
    name    = "text-embedding-3-large"
    version = "1"
  }

  sku {
    name     = "Standard"
    capacity = 50
  }

  depends_on = [azurerm_cognitive_deployment.gpt54]
}
