#!/bin/bash

# Colores para que la terminal se vea profesional
VERDE="\e[32m"
ROJO="\e[31m"
AMARILLO="\e[33m"
AZUL="\e[34m"
RESET="\e[0m"

TARGET=$1

if [ -z "$TARGET" ]; then
  echo -e "\n${ROJO}[!] Error: Necesito un objetivo.${RESET}"
  echo -e "Uso: autohack <IP o DOMINIO>\n"
  exit 1
fi

# Traductor Mágico: Convierte el dominio a IP (si ya es IP, la deja igual)
echo -e "${AMARILLO}[*] Resolviendo objetivo: $TARGET...${RESET}"
IP=$(python3 -c "import sys, socket; print(socket.gethostbyname(sys.argv[1]))" "$TARGET" 2>/dev/null)

if [ -z "$IP" ]; then
  echo -e "${ROJO}[!] Error: No se pudo resolver $TARGET. ¿Lo has añadido a /etc/hosts?${RESET}"
  exit 1
fi

echo -e "${AZUL}=================================================${RESET}"
echo -e "${AZUL}   [!] INICIANDO AUTOHACK CONTRA: ${VERDE}$TARGET ($IP)${RESET}"
echo -e "${AZUL}=================================================${RESET}"

# Creamos la carpeta con el nombre (o la IP)
mkdir -p "$TARGET"

# Nmap usa la IP para mantener la velocidad extrema (-n)
echo -e "${AMARILLO}[+] Fase 1: Escaneo rápido de los 65535 puertos...${RESET}"
nmap -p- --min-rate 5000 -n -Pn $IP -oG "$TARGET/allPorts.txt" > /dev/null

PUERTOS=$(cat "$TARGET/allPorts.txt" | grep -Po '\d{1,5}/open' | awk -F '/' '{print $1}' | paste -sd, -)

if [ -z "$PUERTOS" ]; then
  echo -e "${ROJO}[-] No se encontraron puertos abiertos. Bloquea pings o está apagada.${RESET}"
  exit 1
fi

echo -e "${VERDE}[+] ¡Puertos descubiertos!: $PUERTOS${RESET}"
echo -e "${AMARILLO}[+] Fase 2: Lanzando análisis profundo de Nmap...${RESET}"
nmap -p$PUERTOS -sC -sV $IP -oN "$TARGET/nmap_target.txt" > /dev/null &

# --- ANÁLISIS WEB AVANZADO (Usan TARGET para no perderse los Virtual Hosts) ---
if [[ $PUERTOS == *"80"* ]] || [[ $PUERTOS == *"443"* ]]; then
   echo -e "${VERDE}[!] Servicio Web detectado.${RESET}"
   echo -e "  ├── Lanzando Fuzzing de directorios..."
   ffuf -u http://$TARGET/FUZZ -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -t 50 -c > "$TARGET/web_fuzzing.txt" 2>/dev/null &
   
   echo -e "  ├── Extrayendo tecnologías (WhatWeb)..."
   whatweb $TARGET > "$TARGET/web_tecnologias.txt" &
   
   echo -e "  └── Buscando vulnerabilidades (Nikto)..."
   nikto -h $TARGET -Tuning 123 -o "$TARGET/web_vulnerabilidades.txt" 2>/dev/null &
fi

# --- ANÁLISIS FTP ---
if [[ $PUERTOS == *"21"* ]]; then
   echo -e "${VERDE}[!] Servicio FTP detectado. Comprobando login anónimo...${RESET}"
   nmap -p 21 --script ftp-anon $IP -oN "$TARGET/ftp_anon_check.txt" > /dev/null &
fi

# --- ANÁLISIS SMB (WINDOWS/LINUX) ---
if [[ $PUERTOS == *"445"* ]] || [[ $PUERTOS == *"139"* ]]; then
   echo -e "${VERDE}[!] Servicio SMB detectado.${RESET}"
   echo -e "  ├── Listando recursos compartidos..."
   smbclient -L //$IP/ -N > "$TARGET/smb_shares.txt" 2>/dev/null &
   
   echo -e "  └── Extrayendo usuarios y políticas (Enum4Linux)..."
   enum4linux -a $IP > "$TARGET/smb_enum4linux.txt" 2>/dev/null &
fi

echo -e "${AZUL}=================================================${RESET}"
echo -e "${VERDE}[✓] Arsenal letal desplegado en segundo plano.${RESET}"
echo -e "${AMARILLO}[i] Revisa los archivos de texto en la carpeta: ./$TARGET/${RESET}"
echo -e "${AZUL}=================================================${RESET}"