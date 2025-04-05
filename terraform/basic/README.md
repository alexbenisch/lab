# Terraform + Ansible Provisioning resource for main.tf

```
resource "null_resource" "provision" {
  connection {
    type     = "ssh"
    user     = "alex"
    private_key = file("~/.ssh/id_ed25519")
    host     = hcloud_server.machine.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt install -y ansible || sudo dnf install -y ansible",
      "git clone https://github.com/dein/ansible-repo.git ~/ansible-setup",
      "cd ~/ansible-setup && ansible-playbook -i localhost, playbook.yml --connection=local"
    ]
  }

  depends_on = [hcloud_server.machine]
}

```
