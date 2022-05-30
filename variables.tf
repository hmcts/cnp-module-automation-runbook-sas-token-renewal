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

variable "application_id_collection" {
  type        = list(string)
  description = "List of Application IDs to manage"
  default     = []
}

variable "source_managed_identity_id" {
  type        = string
  description = "Managed Identity to authenticate with. Default will use current context."
  default     = ""
}

variable "name" {
  type        = string
  description = "Runbook Name. Default: rotate-client-secrets"
  default     = "rotate-client-secrets"
}

variable "environment" {
  type        = string
  description = "Environment Name e.g. sbox"
}
variable "product" {
  type        = string
  description = "Product prefix"
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
}

variable "blob_name" {
  type        = string
  description = "Blob Name"
}

variable "secret_name" {
  type        = string
  description = "Secret Name"
}

variable "expiry_date" {
  type        = string
  description = "Expiry date of the SAS token"
}