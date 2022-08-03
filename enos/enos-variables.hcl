variable "aws_region" {
  description = "The AWS region where we'll create infrastructure"
  type        = string
  default     = "us-west-1"
}

variable "aws_ssh_keypair_name" {
  description = "The AWS keypair to use for SSH"
  type        = string
  default     = "enos-ci-ssh-keypair"
}

variable "aws_ssh_private_key_path" {
  description = "The path to the AWS keypair private key"
  type        = string
  default     = "./support/private_key.pem"
}

variable "crt_bundle_path" {
  description = "Path to CRT generated or local vault.zip bundle"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to add to AWS resources"
  type        = map(string)
  default = {
    "Project Name" : "vault-enos-integration",
    "Project" : "Enos",
    "Environment" : "ci"
  }
}

variable "terraform_plugin_cache_dir" {
  description = "The directory to cache Terraform modules and providers"
  type        = string
  // default = null
  default = "./support/terraform-plugin-cache"
}

variable "tfc_api_token" {
  description = "The Terraform Cloud QTI Organization API token."
  type        = string
}

variable "vault_license_path" {
  description = "The path to a valid Vault enterprise edition license. This is only required for non-oss editions"
  type        = string
  default     = null
}
