#!/bin/bash

# Colores para que la terminal se vea profesional
VERDE="\e[32m"
ROJO="\e[31m"
AMARILLO="\e[33m"
AZUL="\e[34m"
RESET="\e[0m"

# 1. Recoger entrada y limpieza automática de URLs (quita http:// y barras)
INPUT=$1

if [ -z "$INPUT" ]; then
  echo -e "\n${ROJO}[!] Error: Necesito un objetivo.${RESET}"
  echo -e "Uso: autohack <IP o DOMINIO>\n"
  exit 1
fi

TARGET=$(echo $INPUT | sed -e 's|^[^/]*//||' -e 's|/.*$||')

# 2. Traductor Mágico (Seguro contra IPv6 usando getent)
echo -e "${AMARILLO}[*] Resolviendo objetivo: $TARGET...${RESET}"
IP=$(getent ahostsv4 "$TARGET" | head -n 1 | awk '{print $1}')

if [ -z "$IP" ]; then
  echo -e "${ROJO}[!] Error: No se pudo resolver $TARGET. ¿Lo has añadido a /etc/hosts?${RESET}"
  exit 1
fi

echo -e "${AZUL}=================================================${RESET}"
echo -e "${AZUL}   [!] INICIANDO AUTOHACK CONTRA: ${VERDE}$TARGET ($IP)${RESET}"
echo -e "${AZUL}=================================================${RESET}"

# Creamos la carpeta con el nombre (o la IP)
mkdir -p "$TARGET"

# 3. Fase 1: Escaneo optimizado (Top 1000 puertos y menos ruido para evitar firewalls)
echo -e "${AMARILLO}[+] Fase 1: Escaneo inicial de los 1000 puertos más comunes...${RESET}"
nmap --top-ports 1000 --min-rate 1000 -T4 -n -Pn $IP -oG "$TARGET/allPorts.txt" > /dev/null

PUERTOS=$(cat "$TARGET/allPorts.txt" | grep -Po '\d{1,5}/open' | awk -F '/' '{print $1}' | paste -sd, -)

if [ -z "$PUERTOS" ]; then
  echo -e "${ROJO}[-] No se encontraron puertos abiertos. Bloquea pings o está apagada.${RESET}"
  exit 1
fi

echo -e "${VERDE}[+] ¡Puertos descubiertos!: $PUERTOS${RESET}"
echo -e "${AMARILLO}[+] Fase 2: Lanzando análisis profundo de Nmap...${RESET}"
nmap -p$PUERTOS -sC -sV $IP -oN "$TARGET/nmap_target.txt" > /dev/null &

# --- ANÁLISIS WEB AVANZADO (Inteligente HTTP/HTTPS) ---
if [[ $PUERTOS == *"80"* ]] || [[ $PUERTOS == *"443"* ]]; then
   # Lógica inteligente: Si el 443 está abierto, usamos HTTPS
   PROTOCOLO="http"
   if [[ $PUERTOS == *"443"* ]]; then
       PROTOCOLO="https"
   fi

   echo -e "${VERDE}[!] Servicio Web detectado ($PROTOCOLO).${RESET}"
   echo -e "  ├── Lanzando Fuzzing de directorios..."
   ffuf -u $PROTOCOLO://$TARGET/FUZZ -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -t 50 -c > "$TARGET/web_fuzzing.txt" 2>/dev/null &
   
   echo -e "  ├── Extrayendo tecnologías (WhatWeb)..."
   whatweb $PROTOCOLO://$TARGET > "$TARGET/web_tecnologias.txt" &
   
   echo -e "  └── Buscando vulnerabilidades (Nikto)..."
   nikto -h $PROTOCOLO://$TARGET -Tuning 123 -o "$TARGET/web_vulnerabilidades.txt" 2>/dev/null &
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