#!/bin/bash
IP=$1
if [ -z "$IP" ]; then
  echo "[!] Uso: ctf-recon <IP_OBJETIVO>"
  exit 1
fi
echo "[+] Lanzando escaneo ultra-rápido de puertos..."
rustscan -a $IP --ulimit 5000 -- -sC -sV -oN "initial_scan.txt"