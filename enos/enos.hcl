terraform_cli "default" {
  plugin_cache_dir = var.terraform_plugin_cache_dir != null ? abspath(var.terraform_plugin_cache_dir) : null

  provider_installation {
    network_mirror {
      url     = "https://enos-provider-stable.s3.amazonaws.com/"
      include = ["hashicorp.com/qti/enos"]
    }
    direct {
      exclude = [
        "hashicorp.com/qti/enos"
      ]
    }
  }

  credentials "app.terraform.io" {
    token = var.tfc_api_token
  }
}

terraform "default" {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

    enos = {
      # source = "app.terraform.io/hashicorp-qti/enos"
      source = "hashicorp.com/qti/enos"
    }
  }
}

provider "aws" "default" {
  region = var.aws_region
}

provider "enos" "rhel" {
  transport = {
    ssh = {
      user             = "ec2_user"
      private_key_path = abspath(var.aws_ssh_private_key_path)
    }
  }
}

provider "enos" "ubuntu" {
  transport = {
    ssh = {
      user             = "ubuntu"
      private_key_path = abspath(var.aws_ssh_private_key_path)
    }
  }
}

module "az_finder" {
  source = "./modules/az_finder"
}

module "backend_consul" {
  source = "app.terraform.io/hashicorp-qti/aws-consul/enos"

  project_name    = "qti-enos-provider"
  environment     = "ci"
  common_tags     = var.tags
  ssh_aws_keypair = "enos-ci-ssh-keypair"

  # Set this to a real license vault if using an Enterprise edition of Consul
  consul_license = "none"
}

module "backend_raft" {
  source = "./modules/backend_raft"
}

module "build_crt" {
  source = "./modules/build_crt"
}

module "build_local" {
  source = "./modules/build_local"
}

module "create_vpc" {
  source = "app.terraform.io/hashicorp-qti/aws-infra/enos"

  project_name      = "qti-enos-provider"
  environment       = "ci"
  common_tags       = var.tags
  ami_architectures = ["amd64", "arm64"]
}

module "vault_cluster" {
  source  = "app.terraform.io/hashicorp-qti/aws-vault/enos"
  version = "0.6.0" // pin to 0.6.0 until VAULT-7338 is fixed.

  project_name    = "vault-enos-integration"
  environment     = "ci"
  common_tags     = var.tags
  ssh_aws_keypair = "enos-ci-ssh-keypair"
}

module "read_license" {
  source = "./modules/read_license"
}

scenario "smoke" {
  matrix {
    arch           = ["amd64", "arm64"]
    backend        = ["consul", "raft"]
    builder        = ["local", "crt"]
    consul_version = ["1.12.3", "1.11.7", "1.10.12"]
    distro         = ["ubuntu", "rhel"]
    edition        = ["oss", "ent"]
    unseal_method  = ["aws_kms", "shamir"]
  }

  terraform_cli = terraform_cli.default
  terraform     = terraform.default
  providers = [
    provider.aws.default,
    provider.enos.ubuntu,
    provider.enos.rhel
  ]

  locals {
    build_path = {
      "local" = "/tmp",
      "crt"   = var.crt_bundle_path == null ? null : abspath(var.crt_bundle_path)
    }
    enos_provider = {
      rhel   = provider.enos.rhel
      ubuntu = provider.enos.ubuntu
    }
    enos_transport_user = {
      rhel   = "ec2-user"
      ubuntu = "ubuntu"
    }
  }

  step "build_vault" {
    module = matrix.builder == "crt" ? module.build_crt : module.build_local

    variables {
      path = local.build_path[matrix.builder]
    }
  }

  step "find_azs" {
    module = module.az_finder

    variables {
      instance_type = [
        var.backend_instance_type,
        var.vault_instance_type
      ]
    }
  }

  step "create_vpc" {
    module = module.create_vpc

    variables {
      ami_architectures  = [matrix.arch]
      availability_zones = step.find_azs.availability_zones
    }
  }

  step "read_license" {
    skip_step = matrix.edition == "oss"
    module    = module.read_license

    variables {
      file_name = abspath(joinpath(path.root, "./support/vault.hclic"))
    }
  }

  step "create_backend_cluster" {
    module     = "backend_${matrix.backend}"
    depends_on = [step.create_vpc]

    providers = matrix.backend == "consul" ? { enos = provider.enos.ubuntu } : {}

    variables {
      ami_id = step.create_vpc.ami_ids[matrix.distro][matrix.arch]
      consul_release = {
        edition = "oss"
        version = matrix.consul_version
      }
      instance_type = var.backend_instance_type
      kms_key_arn   = step.create_vpc.kms_key_arn
      vpc_id        = step.create_vpc.vpc_id
    }
  }

  // TODO: Make shamir unsealing work
  step "create_vault_cluster" {
    module = module.vault_cluster
    depends_on = [
      step.create_vpc,
      step.create_backend_cluster,
    ]

    providers = {
      enos = local.enos_provider[matrix.distro]
    }

    variables {
      ami_id                    = step.create_vpc.ami_ids[matrix.distro][matrix.arch]
      consul_cluster_tag        = step.create_backend_cluster.consul_cluster_tag
      enos_transport_user       = local.enos_transport_user[matrix.distro]
      instance_type             = var.vault_instance_type
      kms_key_arn               = matrix.unseal_method == "aws_kms" ? step.create_vpc.kms_key_arn : null
      storage_backend           = matrix.backend
      vault_local_artifact_path = step.build_vault.artifact_path
      vault_license             = matrix.edition != "oss" ? step.read_license.license : null
      vpc_id                    = step.create_vpc.vpc_id
    }
  }

  output "vault_cluster_instance_ids" {
    description = "The Vault cluster instance IDs"
    value       = step.create_vault_cluster.instance_ids
  }

  output "vault_cluster_pub_ips" {
    description = "The Vault cluster public IPs"
    value       = step.create_vault_cluster.instance_public_ips
  }

  output "vault_cluster_priv_ips" {
    description = "The Vault cluster private IPs"
    value       = step.create_vault_cluster.instance_private_ips
  }

  output "vault_cluster_key_id" {
    description = "The Vault cluster Key ID"
    value       = step.create_vault_cluster.key_id
  }

  output "vault_cluster_root_token" {
    description = "The Vault cluster root token"
    value       = step.create_vault_cluster.vault_root_token
  }

  output "vault_cluster_unseal_keys_b64" {
    description = "The Vault cluster unseal keys"
    value       = step.create_vault_cluster.vault_unseal_keys_b64
  }

  output "vault_cluster_unseal_keys_hex" {
    description = "The Vault cluster unseal keys hex"
    value       = step.create_vault_cluster.vault_unseal_keys_hex
  }

  output "vault_cluster_tag" {
    description = "The Vault cluster tag"
    value       = step.create_vault_cluster.vault_cluster_tag
  }
}
