#!/bin/bash
IP=$1

if [ -z "$IP" ]; then
  echo -e "\n[!] Error: Necesito un objetivo."
  echo -e "Uso: autohack <IP>\n"
  exit 1
fi

echo "================================================="
echo "   [!] INICIANDO AUTOHACK CONTRA: $IP"
echo "================================================="

mkdir -p "$IP"

echo "[+] Fase 1: Escaneo rápido de los 65535 puertos..."
nmap -p- --min-rate 5000 -n -Pn $IP -oG "$IP/allPorts.txt" > /dev/null

PUERTOS=$(cat "$IP/allPorts.txt" | grep -Po '\d{1,5}/open' | awk -F '/' '{print $1}' | paste -sd, -)

if [ -z "$PUERTOS" ]; then
  echo "[-] No se encontraron puertos abiertos."
  exit 1
fi

echo "[+] ¡Puertos descubiertos!: $PUERTOS"
echo "[+] Fase 2: Lanzando análisis profundo..."
nmap -p$PUERTOS -sC -sV $IP -oN "$IP/nmap_target.txt" > /dev/null &

if [[ $PUERTOS == *"80"* ]] || [[ $PUERTOS == *"443"* ]]; then
   echo "[!] Servicio Web detectado. Lanzando Fuzzing en segundo plano..."
   ffuf -u http://$IP/FUZZ -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -t 50 -c > "$IP/web_fuzzing.txt" &
fi

if [[ $PUERTOS == *"21"* ]]; then
   echo "[!] Servicio FTP detectado. Comprobando inicio de sesión anónimo..."
   nmap -p 21 --script ftp-anon $IP -oN "$IP/ftp_anon_check.txt" &
fi

if [[ $PUERTOS == *"445"* ]]; then
   echo "[!] Servicio SMB detectado. Listando recursos compartidos..."
   smbclient -L //$IP/ -N > "$IP/smb_shares.txt" 2>/dev/null &
fi

echo "================================================="
echo "[✓] Arsenal desplegado en segundo plano."
echo "================================================="