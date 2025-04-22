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

resource "hcloud_server" "backpack" {
  name        = "backpack"
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

# Locale-Einstellungen setzen
echo "🌐 Konfiguriere Locale-Einstellungen..."
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
locale-gen C.UTF-8
update-locale LANG=C.UTF-8 LC_ALL=C.UTF-8

# Minimalpakete installieren
apt-get update && apt-get upgrade -y
apt-get install -y git curl zsh sudo locales

# Docker-Gruppe erstellen, falls nicht vorhanden
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

# Dotfiles klonen und Setup vorbereiten
sudo -u alex mkdir -p /home/alex/.local/share
sudo -u alex git clone https://github.com/alexbenisch/dotfiles.git /home/alex/.local/share/dotfiles
chsh -s $(which zsh) alex

# .zshrc vorbereiten für sauberen Zsh-Start
sudo -u alex touch /home/alex/.zshrc
chown alex:alex /home/alex/.zshrc

EOF
}

resource "null_resource" "provision" {
  connection {
    type        = "ssh"
    user        = "alex"
    private_key = file("~/.ssh/id_ed25519")
    host        = hcloud_server.backpack.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "export LC_ALL=C.UTF-8",
      "export LANG=C.UTF-8",
      "locale-gen C.UTF-8",
      "update-locale LANG=C.UTF-8 LC_ALL=C.UTF-8",
      "curl -L https://nixos.org/nix/install | sh",
      ". /home/alex/.nix-profile/etc/profile.d/nix.sh",
      "nix-env -iA nixpkgs.ansible nixpkgs.git",
      "git clone https://github.com/alexbenisch/ansible-repo.git ~/ansible-setup",
      "cd ~/ansible-setup && ansible-playbook -i localhost, playbook.yml --connection=local",
      "curl -L https://nixos.org/nix/install | sh",
      ". /home/alex/.nix-profile/etc/profile.d/nix.sh",
      "nix-env -iA nixpkgs.ansible nixpkgs.git",

    ]
  }

  depends_on = [hcloud_server.backpack]
}

resource "time_sleep" "wait_for_ip" {
  depends_on      = [hcloud_server.backpack]
  create_duration = "30s"
}

output "server_ip" {
  depends_on = [time_sleep.wait_for_ip]
  value      = hcloud_server.backpack.ipv4_address
}

variable "hcloud_token" {}
variable "ssh_key" {}

