terraform {
  required_providers {
    enos = {
      source = "hashicorp.com/qti/enos"
    }
  }
}

variable "path" {
  default = "/tmp"
}

resource "enos_local_exec" "build" {
  environment = {
    "ARTIFACT_PATH" = var.path
    "CGO_ENABLED"   = 0,
    "GOARCH"        = "amd64",
    "GOOS"          = "linux",
    "GO_TAGS"       = "ui netcgo",
  }
  scripts = ["${path.module}/templates/build.sh"]
}

output "artifact_path" {
  value = "${var.path}/vault.zip"
}
