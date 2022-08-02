// Shim module to handle the fact that Vault doesn't actually need a backend module
variable "ami_id" {}
variable "vpc_id" {}
variable "kms_key_arn" {}
variable "consul_release" {}

output "consul_cluster_tag" {
  value = null
}
