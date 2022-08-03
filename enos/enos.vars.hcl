# TODO: make sure this accurately reflects our variables

# aws_region is the region where we'll create test infrastructure
# for the smoke scenario
# aws_region = "us-west-1"

# aws_ssh_keypair_name is the AWS keypair to use for SSH
# aws_ssh_keypair_name = "enos-ci-ssh-keypair"

# aws_ssh_private_key_path is the path to the SSH keypair private key
# aws_ssh_private_key_path = "./support/private_key.pem"

# tags are a map of tags that will be applied to infrastructure resources that
# support tagging.
# tags = { "Project Name" : "Vault", "Something Cool" : "Value" }

# terraform_plugin_cache_dir is a path to a directory where shared Terraform
# resources will be kept. It must exist.
# terraform_plugin_cache_dir = "/Users/<user>/.terraform/plugin-cache-dir

# tfc_api_token is an access token for the QTI organization in Terraform cloud. We need this to download the enos Terraform provider and the enos Terraform modules.
# tfc_api_token = "XXXXX.atlasv1.XXXXX..."

# vault_license_path is the path to a valid Vault Enterprise license. This is
# only required for non-oss editions.

# vault_local_artifact_path is the path to a Vault install bundle, eg. vault.zip. This can be taken
# from releases.hashicorp.com or Artifactory. The local builder variant will create
# one from the existing branch.
# vault_local_artifact_path = "./support/vault.zip"
