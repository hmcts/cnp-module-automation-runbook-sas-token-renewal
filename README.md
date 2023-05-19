# Automation Runbook for Storage SAS Token Renewal

This module is to setup a Azure Automation Runbook to recycle Storage SAS Tokens.



## Example

Below is the standard example setup for generating a token for Storage Account

```terraform
module "automation_runbook_sas_token_renewal" {
  source = "git@github.com:hmcts/cnp-module-automation-runbook-sas-token-renewal?ref=master"

  resource_group_name = "my-resource-group"
  tags                = var.common_tags

  application_id_collection = [
    "6d992660-4d87-4294-8007-dbf7b6c0a1e5",
    "60779d15-7cf9-46ab-ba6a-b77b64ef5093"
  ]

  environment = "sbox"
  product     = "hcm"

  key_vault_name = "hcm-kv-sbox"

  automation_account_name = "hcm-automation"

  storage_account_name = "hcm-storage"

  secret_name = "sas-token-secret"

  expiry_days = 10

}
```

### Optional
If you would like to generate a token for a Container or a Blob, then you will need to add either just the Container Name or both for a Blob SAS token.

```terraform
container_name = "hcm-container"
blob_name      = "hcm-blob"
```

### Terraform Spec

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_automation_job_schedule.client_serects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_job_schedule) | resource |
| [azurerm_automation_job_schedule.client_serects_trigger_once](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_job_schedule) | resource |
| [azurerm_automation_runbook.client_serects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook) | resource |
| [azurerm_automation_schedule.client_serects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) | resource |
| [azurerm_automation_schedule.client_serects_trigger_once](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_automation_account_name"></a> [automation\_account\_name](#input\_automation\_account\_name) | Automation Account Name | `string` | n/a | yes |
| <a name="input_blob_name"></a> [blob\_name](#input\_blob\_name) | Blob Name | `string` | n/a | yes |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | Container Name | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name e.g. sbox | `string` | n/a | yes |
| <a name="input_expiry_days"></a> [expiry\_days](#input\_expiry\_days) | Number of days the SAS should last | `int` | 30 | yes |
| <a name="remaining_days"></a> [remaining\_days](#input\_remaining\_days) | Number of days remaining for which the SAS token should be renewed | `int` | 5 | yes |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | Key Vault Name to store secrets | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Location of Runbook | `string` | `"uksouth"` | no |
| <a name="input_name"></a> [name](#input\_name) | Runbook Name. Default: rotate-sas-tokens | `string` | `"rotate-sas-tokens"` | no |
| <a name="input_product"></a> [product](#input\_product) | Product prefix | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group Name | `string` | n/a | yes |
| <a name="input_sas_permissions"></a> [sas\_permissions](#input\_sas\_permissions) | Permissions to assign to SAS token. Specified as letters as per https://docs.microsoft.com/en-gb/rest/api/storageservices/create-account-sas#account-sas-permissions-by-operation | `string` | `"rl"` | no |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | Secret Name | `string` | n/a | yes |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | Storage Account Name | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Runbook Tags | `map(string)` | n/a | yes |

## Outputs

No outputs.