
locals {
  runbook_name    = "renew_sas.ps1"
  runbook_content = file("${path.module}/${local.runbook_name}")
}

resource "azurerm_automation_runbook" "main" {
  name                    = var.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  log_verbose             = var.environment == "prod" ? "false" : "true"
  log_progress            = "true"
  description             = "This is a runbook to automate the recycling of SAS tokens on ${var.storage_account_name}"
  runbook_type            = "PowerShell"

  content = local.runbook_content

  tags = var.tags
}
