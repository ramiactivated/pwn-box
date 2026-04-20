#!/bin/bash
echo "=== INICIANDO INSTALACIÓN DE HERRAMIENTAS CTF ==="

# 1. Actualizar el sistema
apt-get update -y
apt-get upgrade -y

# 2. Instalar herramientas básicas
apt-get install -y nmap ffuf gobuster git curl wget python3 python3-pip unzip sudo

# 2.5 Instalar dependencias para el Autohack Avanzado (Web y SMB)
echo "=== INSTALANDO HERRAMIENTAS DE ANÁLISIS PROFUNDO ==="
apt-get install -y nikto whatweb enum4linux smbclient

# 3. Descargar SecLists (Diccionarios para Fuzzing)
echo "Descargando SecLists..."
mkdir -p /usr/share/seclists
git clone --depth 1 https://github.com/danielmiessler/SecLists.git /usr/share/seclists

# 4. Configurar Estética (Zsh, Starship y MOTD)
echo "=== CONFIGURANDO ESTÉTICA ==="
apt-get install -y zsh figlet tmux
curl -sS https://starship.rs/install.sh | sh -s -- -y
echo 'eval "$(starship init zsh)"' >> /etc/zsh/zshrc
chsh -s $(which zsh) root

# Crear el Banner de Bienvenida
figlet -f slant "PWN BOX" > /etc/motd
echo "Distro CTF Optimizada | Debian 12 Base" >> /etc/motd
echo "----------------------------------------" >> /etc/motd

# 5. Configurar Arsenal Avanzado (LinPEAS y Docker)
echo "=== CONFIGURANDO ARSENAL AVANZADO ==="
mkdir -p /opt/privesc
echo "Descargando LinPEAS..."
wget -q https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh -O /opt/privesc/linpeas.sh
chmod +x /opt/privesc/linpeas.sh

echo "Instalando Docker..."
apt-get install -y docker.io
systemctl enable docker

# 6. Mover scripts personalizados a binarios globales
echo "=== CONFIGURANDO COMANDOS GLOBALES ==="

# ¡LA VACUNA!: Limpiar caracteres de Windows (CRLF) de todos los scripts
sed -i 's/\r$//' /tmp/scripts/*.sh

# Mover ctf-recon
mv /tmp/scripts/ctf-recon.sh /usr/local/bin/ctf-recon
chmod +x /usr/local/bin/ctf-recon

# Mover revshell
mv /tmp/scripts/revshell.sh /usr/local/bin/revshell
chmod +x /usr/local/bin/revshell

# Mover autohack
mv /tmp/scripts/autohack.sh /usr/local/bin/autohack
chmod +x /usr/local/bin/autohack

echo "=== INSTALACIÓN COMPLETADA CON ÉXITO ==="