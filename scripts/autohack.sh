#!/bin/bash

# ==========================================
# COLORES PROFESIONALES
# ==========================================
C_VERDE="\e[1;32m"
C_ROJO="\e[1;31m"
C_AMARILLO="\e[1;33m"
C_AZUL="\e[1;34m"
C_CYAN="\e[1;36m"
RESET="\e[0m"

# ==========================================
# MENÚ DE AYUDA Y VALIDACIÓN
# ==========================================
if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ -z "$1" ]; then
    echo -e "${C_CYAN}"
    echo -e "    _         _        _   _            _    "
    echo -e "   / \  _   _| |_ ___ | | | | __ _  ___| | __"
    echo -e "  / _ \| | | | __/ _ \| |_| |/ _\` |/ __| |/ /"
    echo -e " / ___ \ |_| | || (_) |  _  | (_| | (__|   < "
    echo -e "/_/   \_\__,_|\__\___/|_| |_|\__,_|\___|_|\_\\"
    echo -e "                                             "
    echo -e "${RESET}Herramienta de Reconocimiento Ofensivo Automatizado"
    echo -e "\n${C_AMARILLO}Uso:${RESET} autohack <objetivo>"
    echo -e "${C_AMARILLO}Ejemplos:${RESET}"
    echo -e "  autohack 10.10.10.5"
    echo -e "  autohack maquina.htb"
    echo -e "  autohack https://google.com\n"
    exit 0
fi

# ==========================================
# LIMPIEZA DE ENTRADA Y RESOLUCIÓN DNS
# ==========================================
# Extrae solo el dominio/IP (quita http://, https:// y barras finales)
TARGET=$(echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||')

echo -e "${C_AZUL}[*] Preparando armamento contra: ${C_AMARILLO}$TARGET${RESET}"

# Resolución DNS forzada a IPv4 (A prueba de fallos)
IP=$(getent ahostsv4 "$TARGET" | head -n 1 | awk '{print $1}')

if [ -z "$IP" ]; then
    echo -e "${C_ROJO}[!] ERROR FATAL: No se pudo resolver $TARGET.${RESET}"
    echo -e "Verifica tu conexión o tu archivo /etc/hosts."
    exit 1
fi

echo -e "${C_VERDE}[✓] Objetivo fijado en IP: $IP${RESET}\n"

# Crear directorio de trabajo aislado
mkdir -p "$TARGET"

# ==========================================
# FASE 1: RECONOCIMIENTO SIGILOSO (Bypass WAF)
# ==========================================
echo -e "${C_CYAN}[+] FASE 1: Escaneando los 1000 puertos principales...${RESET}"
# Usamos min-rate 1000 para no saturar firewalls, pero mantener velocidad
nmap --top-ports 1000 --min-rate 1000 -T4 -n -Pn "$IP" -oG "$TARGET/allPorts.txt" > /dev/null

# Extraer puertos limpios separados por comas
PUERTOS=$(grep -Po '\d{1,5}/open' "$TARGET/allPorts.txt" | awk -F '/' '{print $1}' | paste -sd, -)

if [ -z "$PUERTOS" ]; then
    echo -e "${C_ROJO}[-] El escudo es impenetrable. No hay puertos abiertos o el servidor bloquea escaneos.${RESET}"
    rm -rf "$TARGET"
    exit 1
fi

echo -e "${C_VERDE}[✓] Puertos vulnerables detectados: $PUERTOS${RESET}"

# ==========================================
# FASE 2: EXTRACCIÓN DE INTELIGENCIA
# ==========================================
echo -e "${C_CYAN}[+] FASE 2: Identificación de versiones y scripts de Nmap...${RESET}"
nmap -p"$PUERTOS" -sC -sV "$IP" -oN "$TARGET/nmap_target.txt" > /dev/null &

# ==========================================
# FASE 3: VECTORES DE ATAQUE ESPECÍFICOS
# ==========================================
echo -e "${C_CYAN}[+] FASE 3: Desplegando módulos ofensivos en segundo plano...${RESET}"

# --- MÓDULO WEB (HTTP/HTTPS Inteligente) ---
if [[ "$PUERTOS" == *"80"* ]] || [[ "$PUERTOS" == *"443"* ]]; then
    PROTOCOLO="http"
    [[ "$PUERTOS" == *"443"* ]] && PROTOCOLO="https"
   
    echo -e "  ${C_VERDE}├── [Web]${RESET} Lanzando Ffuf, WhatWeb y Nikto sobre $PROTOCOLO..."
    ffuf -u "$PROTOCOLO://$TARGET/FUZZ" -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -t 50 -c > "$TARGET/web_fuzzing.txt" 2>/dev/null &
    whatweb "$PROTOCOLO://$TARGET" > "$TARGET/web_tecnologias.txt" &
    nikto -h "$PROTOCOLO://$TARGET" -Tuning 123 -o "$TARGET/web_vulnerabilidades.txt" 2>/dev/null &
fi

# --- MÓDULO FTP ---
if [[ "$PUERTOS" == *"21"* ]]; then
    echo -e "  ${C_VERDE}├── [FTP]${RESET} Verificando acceso anónimo..."
    nmap -p 21 --script ftp-anon "$IP" -oN "$TARGET/ftp_anon_check.txt" > /dev/null &
fi

# --- MÓDULO SMB (Windows/Samba) ---
if [[ "$PUERTOS" == *"445"* ]] || [[ "$PUERTOS" == *"139"* ]]; then
    echo -e "  ${C_VERDE}├── [SMB]${RESET} Enumerando usuarios y carpetas compartidas..."
    smbclient -L //"$IP"/ -N > "$TARGET/smb_shares.txt" 2>/dev/null &
    enum4linux -a "$IP" > "$TARGET/smb_enum4linux.txt" 2>/dev/null &
fi

echo -e "\n${C_AZUL}================================================================${RESET}"
echo -e "${C_VERDE} [✓] ATAQUE AUTOMATIZADO DESPLEGADO CON ÉXITO${RESET}"
echo -e "${C_AMARILLO} [i] Las herramientas están trabajando en segundo plano.${RESET}"
echo -e "${C_AMARILLO} [i] Accede a la inteligencia recolectada con: ${C_CYAN}cd $TARGET/${RESET}"
echo -e "${C_AZUL}================================================================${RESET}"