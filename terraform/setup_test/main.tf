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
  ssh_keys    = [hcloud_ssh_key.alex.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  user_data = <<-EOF
#!/bin/bash

# Logging konfigurieren
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting setup: $(date)"

# Pakete aktualisieren und installieren
apt-get update && apt-get upgrade -y
apt-get install -y zsh tmux fzf ripgrep git

# Docker-Gruppe erstellen falls nicht vorhanden
groupadd -f docker

# Benutzer erstellen (falls nicht durch cloud-init gemacht)
if ! id -u alex >/dev/null 2>&1; then
  useradd -m -s /bin/zsh -G sudo,docker alex
  echo 'alex ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/alex
  chmod 0440 /etc/sudoers.d/alex
fi

# SSH-Key einrichten
mkdir -p /home/alex/.ssh
echo '${var.ssh_key}' >> /home/alex/.ssh/authorized_keys
chmod 700 /home/alex/.ssh
chmod 600 /home/alex/.ssh/authorized_keys
chown -R alex:alex /home/alex/.ssh

# Dotfiles klonen und Setup ausführen
sudo -u alex mkdir -p /home/alex/.local/share
sudo -u alex git clone https://github.com/alexbenisch/dotfiles /home/alex/.local/share/dotfiles
chsh -s $(which zsh) alex

cd /home/alex/.local/share/dotfiles
sudo -u alex bash setup

# Abschlussmeldung
echo "SETUP_COMPLETE: $(date)" | tee /home/alex/setup_completed.log
chmod 644 /home/alex/setup_completed.log
chown alex:alex /home/alex/setup_completed.log

echo "Setup finished: $(date)"
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





