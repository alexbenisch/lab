terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~>1.44"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~>2.3"
    }
  }
}
data "external" "hcloud_token" {
  program = ["sh", "-c", "echo '{\"value\": \"'\"$HCLOUD_TOKEN\"'\"}'"]
}

provider "hcloud" {
  token = data.external.hcloud_token.result.value
}

provider "http" {}

data "http" "github_keys" {
  url = "https://github.com/${var.github_username}.keys"
}

locals {
  github_ssh_keys = split("\n", trimspace(data.http.github_keys.response_body))
}

output "ssh_keys" {
  value = local.github_ssh_keys
}

resource "hcloud_ssh_key" "github" {
  name       = "github-key"
  public_key = local.github_ssh_keys[0]
}

resource "hcloud_server" "machine" {
  name        = "machine"
  image       = "debian-12"
  server_type = "cpx11"
  location    = "fsn1"
  ssh_keys    = [hcloud_ssh_key.github.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}

variable "github_username" {
  description = "GitHub Username für SSH Public Keys"
  type        = string
}

variable "ssh_keys" {
  description = "Liste der SSH Public Keys"
  type        = list(string)
  default     = []
}

variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
}
