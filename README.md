# 🛡️ Pwn-Box: Laboratorio CTF Automatizado

Este proyecto utiliza **Packer** e **Infraestructura como Código (IaC)** para generar una máquina virtual Debian 12 personalizada y lista para entornos de hacking ético y CTFs.

## 🚀 Características principales
- **Instalación Desatendida:** Configuración automática mediante `preseed.cfg`.
- **Entorno Visual:** Terminal Zsh con Starship prompt y banners ASCII.
- **Herramientas de Reconocimiento:**
  - `autohack`: Script de automatización que escanea puertos, detecta servicios y lanza herramientas de fuerza bruta o fuzzing automáticamente.
  - `revshell`: Generador rápido de payloads para reverse shells.
  - `ctf-recon`: Escáner rápido de puertos abiertos.
- **Arsenal Preinstalado:** Nmap, Ffuf, Docker, SecLists, LinPEAS y más.

## 🏗️ Cómo construir la máquina
1. Instala Packer y VirtualBox.
2. Ejecuta el siguiente comando en la raíz del proyecto:
   ```bash
   packer build -force packer/debian.pkr.hcl