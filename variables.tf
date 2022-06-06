variable "location" {
  type        = string
  description = "Location of Runbook"
  default     = "uksouth"
}
variable "resource_group_name" {
  type        = string
  description = "Resource Group Name"
}
variable "tags" {
  type        = map(string)
  description = "Runbook Tags"
}

variable "name" {
  type        = string
  description = "Runbook Name. Default: rotate-sas-tokens"
  default     = "rotate-sas-tokens"
}

variable "environment" {
  type        = string
  description = "Environment Name e.g. sbox"
}

variable "key_vault_name" {
  type        = string
  description = "Key Vault Name to store secrets"
}

variable "automation_account_name" {
  type        = string
  description = "Automation Account Name"
}

variable "storage_account_name" {
  type        = string
  description = "Storage Account Name"
}

variable "container_name" {
  type        = string
  description = "Container Name"
  default     = ""
}

variable "blob_name" {
  type        = string
  description = "Blob Name"
  default     = ""
}

variable "secret_name" {
  type        = string
  description = "Secret Name"
}

variable "expiry_date" {
  type        = string
  description = "Expiry date of the SAS token"
}

variable "sas_permissions" {
  type        = string
  description = "Permissions to assign to SAS token. Specified as letters as per https://docs.microsoft.com/en-gb/rest/api/storageservices/create-account-sas#account-sas-permissions-by-operation"
  default     = "rl"
}
