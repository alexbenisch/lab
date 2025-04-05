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
  name       = "alex-desktop"
  public_key = file("~/.ssh/id_ed25519.pub") # oder direkt als Variable
}
resource "hcloud_server" "basic" {
  name        = "basic"
  image       = "debian-12"
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
        groups: ["sudo","docker"]
        shell: /bin/zsh
        sudo: ["ALL=(ALL) NOPASSWD:ALL"]
        ssh-authorized-keys:
          - ${var.ssh_key}
        lock_passwd: false
        passwd: "$6$rounds=4096$XJ5p3uJ5HUE68...hashedpassword..."  # Verschlüsseltes Passwort
    runcmd:
      - sudo -u alex git clone https://github.com/alexbenisch/dotfiles.git /home/alex/.local/share/dotfiles
      - chsh -s $(which zsh) alex
      - sudo -u alex bash /home/alex/.local/share/dotfiles/setup.sh
      - echo "SETUP_COMPLETE: $(date)" | sudo tee /home/alex/setup_completed.log
      - chmod 644 /home/alex/setup_completed.log
      - chown alex:alex /home/alex/setup_completed.log
  EOF
}
resource "time_sleep" "wait_for_ip" {
  depends_on = [hcloud_server.basic]

  create_duration = "30s" # Wartezeit (anpassen je nach Hetzner Geschwindigkeit)
}

output "server_ip" {
  depends_on = [time_sleep.wait_for_ip]
  value      = hcloud_server.basic.ipv4_address
}
variable "hcloud_token" {}
variable "ssh_key" {}





