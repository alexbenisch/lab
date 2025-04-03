terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~>1.44"
    }
  }
}
provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "alex" {
  name       = "alex@tpad"
  public_key = file(var.tpad_ssh_key)
  name       = "alex@seven"
  public_key = file(var.desktop_ssh_key)
}


resource "hcloud_server" "machine" {
  name        = "machine"
  image       = "debian-12"
  server_type = "cpx11"
  location    = "fsn1"
  ssh_keys    = [hcloud_tpad_ssh_key.alex.id,hcloud_desktop_ssh_key]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  user_data = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - zsh
      - gnupg
      - git
      - machine
      - tmux
      - fzf
      - ripgrep

users:
  - name: alex
    groups: ["wheel"]
    shell: /bin/zsh
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh-authorized-keys:
      - ${hcloud_ssh_key.alex.public_key}
    lock_passwd: false
    passwd: "$6$rounds=4096$XJ5p3uJ5HUE68...hashedpassword..."




variable "hcloud_token" {}
