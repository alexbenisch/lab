terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
    version = "~> 1.44"
    }
  }
}


provider "hcloud" {
  token = var.hcloud_token
  
}
resource "hcloud_ssh_key" "alex" {
  name       = "alex-laptop"
  public_key = file("~/.ssh/id_ed25519.pub") # oder direkt als Variable
}
resource "hcloud_server" "stow" {
  name        = "stow"
  image       = "fedora-41"
  server_type = "cpx11"
  location    = "fsn1"
  ssh_keys    = [hcloud_ssh_key.alex.id] # Statt var.ssh_key
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
      - stow
      - tmux
      - fzf
      - ripgrep
      - git

    users:
      - name: alex
        groups: ["wheel"]
        shell: /bin/zsh
        sudo: ["ALL=(ALL) NOPASSWD:ALL"]
        ssh-authorized-keys:
          - ${var.ssh_key}
        lock_passwd: false
        passwd: "$6$rounds=4096$XJ5p3uJ5HUE68...hashedpassword..."  # Verschlüsseltes Passwort

    runcmd:
      - sudo -u alex git clone https://github.com/alexbenisch/dotfiles.git /home/alex/.local/share/dotfiles
      - chsh -s $(which zsh) alex
  EOF
}

variable "hcloud_token" {}
variable "ssh_key" {}

