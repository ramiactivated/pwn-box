#!/bin/bash
set -e # Detiene la instalación si ocurre un error crítico

echo "================================================="
echo "   [!] INICIANDO DESPLIEGUE DE INFRAESTRUCTURA   "
echo "================================================="

# 1. Actualización y Herramientas Base (Incluye OpenVPN para CTFs)
echo "[+] 1/6 Actualizando repositorios e instalando base..."
apt-get update -y
apt-get install -y curl wget git python3 nmap docker.io zsh openvpn unzip python3-pip

# 2. Dependencias de Perl y WhatWeb (Para herramientas ofensivas)
echo "[+] 2/6 Instalando dependencias de red y Perl..."
apt-get install -y perl smbclient samba-common-bin whatweb
apt-get install -y libjson-perl libxml-writer-perl libnet-ssleay-perl

# 3. Instalación de herramientas avanzadas (GitHub, Ruby y Binarios)
echo "[+] 3/6 Clonando herramientas y descargando arsenal avanzado..."

# Nikto y Enum4linux
if [ ! -d "/opt/nikto" ]; then
    git clone https://github.com/sullo/nikto /opt/nikto
    ln -sf /opt/nikto/program/nikto.pl /usr/local/bin/nikto
fi
if [ ! -d "/opt/enum4linux" ]; then
    git clone https://github.com/CiscoCXSecurity/enum4linux /opt/enum4linux
    ln -sf /opt/enum4linux/enum4linux.pl /usr/local/bin/enum4linux
fi

# WPScan (Añadidas herramientas de compilación base)
echo "  ├── Instalando WPScan y dependencias..."
apt-get install -y ruby-dev build-essential libcurl4-openssl-dev
gem install wpscan > /dev/null 2>&1 || true

# Nuclei (Usando binario precompilado ultra-rápido)
echo "  └── Descargando Nuclei (Binario directo)..."
wget -q https://github.com/projectdiscovery/nuclei/releases/download/v3.2.2/nuclei_3.2.2_linux_amd64.zip -O /tmp/nuclei.zip
unzip -q /tmp/nuclei.zip -d /tmp/
mv /tmp/nuclei /usr/local/bin/nuclei
chmod +x /usr/local/bin/nuclei
rm /tmp/nuclei.zip
# Actualizamos plantillas sin que rompa el script si hay un corte de red
nuclei -update-templates > /dev/null 2>&1 || true

# 4. Diccionarios (SecLists)
echo "[+] 4/6 Descargando SecLists (Diccionarios)..."
mkdir -p /usr/share/seclists
if [ ! -d "/usr/share/seclists/Discovery" ]; then
    git clone https://github.com/danielmiessler/SecLists.git /usr/share/seclists
fi

# 5. Herramientas de Escalada de Privilegios
echo "[+] 5/6 Descargando LinPEAS..."
mkdir -p /opt/privesc
wget -q https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh -O /opt/privesc/linpeas.sh
chmod +x /opt/privesc/linpeas.sh

# 6. Vacuna Windows y Configuración de Comandos Globales
echo "[+] 6/6 Inmunizando scripts y creando accesos globales..."

# LA VACUNA: Limpia los saltos de línea de Windows (CRLF a LF) en todos los scripts
sed -i 's/\r$//' /tmp/scripts/*.sh

# Mover y dar permisos a los scripts personalizados
mv /tmp/scripts/ctf-recon.sh /usr/local/bin/ctf-recon 2>/dev/null || true
chmod +x /usr/local/bin/ctf-recon 2>/dev/null || true

mv /tmp/scripts/revshell.sh /usr/local/bin/revshell 2>/dev/null || true
chmod +x /usr/local/bin/revshell 2>/dev/null || true

mv /tmp/scripts/autohack.sh /usr/local/bin/autohack
chmod +x /usr/local/bin/autohack

echo "================================================="
echo "   [✓] INFRAESTRUCTURA DESPLEGADA CON ÉXITO      "
echo "================================================="