#!/bin/bash

source /etc/os-release
if [[ "$ID" != 'debian' ]]; then
 YourBanner
 echo -e "[\e[1;31mError\e[0m] This script is for Debian Machine only, exting..." 
 exit 1
fi

if [[ $EUID -ne 0 ]];then
 YourBanner
 echo -e "[\e[1;31mError\e[0m] This script must be run as root, exiting..."
 exit 1
fi

function Installation(){
 cd /root
 export DEBIAN_FRONTEND=noninteractive
 apt-get update
 apt-get upgrade -y
 apt-get install wget nano dante-server netcat -y &> /dev/null | echo '[*] Installing SOCKS5 Server...'
 cat <<'EOF'> /etc/danted.conf
logoutput: /var/log/socks.log
internal: 0.0.0.0 port = SOCKSPORT
external: SOCKSINET
socksmethod: SOCKSAUTH
user.privileged: root
user.notprivileged: nobody
client pass {
 from: 0.0.0.0/0 to: 0.0.0.0/0
 log: error connect disconnect
 }
 
client block {
 from: 0.0.0.0/0 to: 0.0.0.0/0
 log: connect error
 }
 
socks pass {
 from: 0.0.0.0/0 to: 0.0.0.0/0
 log: error connect disconnect
 }
 
socks block {
 from: 0.0.0.0/0 to: 0.0.0.0/0
 log: connect error
 }
EOF
 sed -i "s/SOCKSINET/$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)/g" /etc/danted.conf
 sed -i "s/SOCKSPORT/$SOCKSPORT/g" /etc/danted.conf
 sed -i "s/SOCKSAUTH/$SOCKSAUTH/g" /etc/danted.conf
 sed -i '/\/bin\/false/d' /etc/shells
 echo '/bin/false' >> /etc/shells
 systemctl restart danted.service
 systemctl enable danted.service
}
 
function Uninstallation(){
 echo -e '[*] Uninstalling SOCKS5 Server'
 apt-get remove --purge dante-server &> /dev/null
 rm -rf /etc/danted.conf
 echo -e '[√] SOCKS5 Server successfully uninstalled and removed.'
}

function SuccessMessage(){
 clear
 echo -e " Your SOCKS5 Proxy IP Address: $(wget -4qO- http://ipinfo.io/ip)"
 echo -e " Your SOCKS5 Proxy Port: $SOCKSPORT"
 if [ "$SOCKSAUTH" == 'username' ]; then
 echo -e " Your SOCKS5 Authentication:"
 echo -e " SOCKS5 Username: $socksUser"
 echo -e " SOCKS5 Password: $socksPass"
 fi
 echo -e " Install.txt can be found at /root/socks5.txt"
 cat <<EOF> ~/socks5.txt
==Your SOCKS5 Proxy Information==
IP Address: $(wget -4qO- http://ipinfo.io/ip)
Port: $SOCKSPORT
EOF
 if [ "$SOCKSAUTH" == 'username' ]; then
 cat <<EOF>> ~/socks5.txt
Username: $socksUser
Password: $socksPass
EOF
 fi
 cat ~/socks5.txt 
}
echo -e " Choose SOCKS5 Proxy Type"
echo -e " [1] Private Proxy (Can be Accessable using username and password Authentication)"
echo -e " [2] Uninstall SOCKS5 Proxy Server"
until [[ "$opts" =~ ^[1-2]$ ]]; do
	read -rp " Choose from [1-2]: " -e opts
	done
	case $opts in
	1)
	until [[ "$SOCKSPORT" =~ ^[0-9]+$ ]] && [ "$SOCKSPORT" -ge 1 ] && [ "$SOCKSPORT" -le 65535 ]; do
	SOCKSPORT=17362
	done
	SOCKSAUTH='username'
	until [[ "$socksUser" =~ ^[a-zA-Z0-9_]+$ ]]; do
	read -rp " Your SOCKS5 Username: " -e socksUser
	done
	until [[ "$socksPass" =~ ^[a-zA-Z0-9_]+$ ]]; do
	read -rp " Your SOCKS5 Password: " -e socksPass
	done
	userdel -r -f $socksUser &> /dev/null
	useradd -m -s /bin/false $socksUser
	echo -e "$socksPass\n$socksPass\n" | passwd $socksUser &> /dev/null
	Installation
	;;
	2)
	Uninstallation
	exit 1
	;;
esac
SuccessMessage
exit 1
