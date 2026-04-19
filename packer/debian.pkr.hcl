packer {
  required_plugins {
    virtualbox = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

source "virtualbox-iso" "ctf-box" {
  guest_os_type    = "Debian_64"
  iso_url          = "https://cdimage.debian.org/cdimage/archive/12.5.0/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
  iso_checksum     = "sha256:013f5b44670d81280b5b1bc02455842b250df2f0c6763398feb69af1a805a14f"
  ssh_username     = "root"
  ssh_password     = "toor"
  ssh_timeout      = "30m"
  vm_name          = "Mi-Distro-CTF"
  cpus             = 2
  memory           = 2048
  
  http_directory   = "packer/http"
  shutdown_command = "/sbin/shutdown -hP now"
  
boot_command = [
    "<wait5>",
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "netcfg/get_hostname=ctfbox netcfg/get_domain=local ",
    "locale=es_ES.UTF-8 keyboard-configuration/xkb-keymap=es ",
    "priority=critical <enter>"
  ]
}

# --- ESTA ES LA PARTE QUE SE HA ACTUALIZADO ---
build {
  sources = ["source.virtualbox-iso.ctf-box"]

  # 1. Sube tu carpeta entera de scripts a la carpeta temporal de la máquina virtual
  provisioner "file" {
    source      = "scripts"
    destination = "/tmp/"
  }

  # 2. Ejecuta el script maestro de instalación dentro de la máquina
  provisioner "shell" {
    script = "scripts/setup.sh"
  }
}