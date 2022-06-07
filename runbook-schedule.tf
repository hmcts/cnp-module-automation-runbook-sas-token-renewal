data "azurerm_client_config" "current" {}
locals {
  source_tenant_id = data.azurerm_client_config.current.tenant_id

  today      = timestamp()
  start_date = formatdate("YYYY-MM-DD", timeadd(local.today, "24h"))
  start_time = "01:00:00"

  parameters = {
    environment          = var.environment
    storage_account_name = var.storage_account_name
    container_name       = var.container_name
    blob_name            = var.blob_name
    key_vault_name       = var.key_vault_name
    secret_name          = var.secret_name
    permissions          = var.sas_permissions
    start_date           = timestamp()
    expiry_date          = var.expiry_date

  }
}

resource "azurerm_automation_schedule" "schedule" {
  name                    = "${var.name}-schedule"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  frequency               = "Day"
  interval                = 1
  start_time              = "${local.start_date}T${local.start_time}Z"
  description             = "This is a schedule to automate the recycling of SAS tokens on ${var.storage_account_name}"
}

resource "azurerm_automation_schedule" "trigger_once" {
  name                    = "${var.name}-schedule-single-trigger"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  frequency               = "OneTime"
  start_time              = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timeadd(local.today, "10m"))
  description             = "This is a one time trigger to automate the recycling of SAS tokens on ${var.storage_account_name}"
}

resource "azurerm_automation_job_schedule" "schedule" {
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  schedule_name           = azurerm_automation_schedule.schedule.name
  runbook_name            = azurerm_automation_runbook.main.name
  parameters              = local.parameters
  depends_on              = [azurerm_automation_schedule.schedule]
}

resource "azurerm_automation_job_schedule" "trigger_once" {
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  schedule_name           = azurerm_automation_schedule.trigger_once.name
  runbook_name            = azurerm_automation_runbook.main.name
  parameters              = local.parameters
  depends_on              = [azurerm_automation_schedule.trigger_once]
}