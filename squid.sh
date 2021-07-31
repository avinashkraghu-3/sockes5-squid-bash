#!/bin/bash

function Installation(){

if [ `whoami` != root ]; then
	echo "ERROR: You need to run the script as user root or add sudo before command."
	exit 1
fi

#update repository
/usr/bin/apt update

if [[ -d /etc/squid/ || -d /etc/squid3/ ]]; then
    echo "Squid Proxy already installed. If you want to reinstall, first uninstall squid proxy by running command: squid-uninstall"
    exit 1
fi

#squid variable

squid_user="admin"
read -e -i "$squid_user" -p "squid_default (username:admin):" input
squid_user="${input:-$squid_user}"

squid_password="qwerty@123"
read -e -i "$squid_password" -p "squid_default (password:qwerty@123):" input1
squid_password="${input1:-$squid_password}"


#squid_user=admin 
#squid_password=fox

#install required packages
/usr/bin/apt -y install apache2-utils squid3 wget

#download squid configuration file
cat <<EOF > /etc/squid/squid-1.conf
acl localnet src 0.0.0.1-0.255.255.255	
acl localnet src 10.0.0.0/8		
acl localnet src 100.64.0.0/10		
acl localnet src 169.254.0.0/16 	
acl localnet src 172.16.0.0/12		
acl localnet src 192.168.0.0/16		
acl localnet src fc00::/7       	
acl localnet src fe80::/10      	
acl SSL_ports port 443
acl Safe_ports port 80		
acl Safe_ports port 21		
acl Safe_ports port 443		
acl Safe_ports port 70		
acl Safe_ports port 210		
acl Safe_ports port 1025-65535	
acl Safe_ports port 280		
acl Safe_ports port 488		
acl Safe_ports port 591		
acl Safe_ports port 777		
acl CONNECT method CONNECT
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
include /etc/squid/conf.d/*
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/squid_passwd
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
forwarded_for off
request_header_access Allow allow all
request_header_access Authorization allow all
request_header_access WWW-Authenticate allow all
request_header_access Proxy-Authorization allow all
request_header_access Proxy-Authenticate allow all
request_header_access Cache-Control allow all
request_header_access Content-Encoding allow all
request_header_access Content-Length allow all
request_header_access Content-Type allow all
request_header_access Date allow all
request_header_access Expires allow all
request_header_access Host allow all
request_header_access If-Modified-Since allow all
request_header_access Last-Modified allow all
request_header_access Location allow all
request_header_access Pragma allow all
request_header_access Accept allow all
request_header_access Accept-Charset allow all
request_header_access Accept-Encoding allow all
request_header_access Accept-Language allow all
request_header_access Content-Language allow all
request_header_access Mime-Version allow all
request_header_access Retry-After allow all
request_header_access Title allow all
request_header_access Connection allow all
request_header_access Proxy-Connection allow all
request_header_access User-Agent allow all
request_header_access Cookie allow all
request_header_access All deny all
http_access allow localhost
http_access deny all
http_port 17361
coredump_dir /var/spool/squid
refresh_pattern ^ftp:		1440	20%	10080
refresh_pattern ^gopher:	1440	0%	1440
refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
refresh_pattern .		0	20%	4320
EOF

#backup default configuration file
sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.default

#mv downloaded squid file and replace to original 
sudo mv /etc/squid/squid-1.conf /etc/squid/squid.conf

#Create squid_passwd file
/usr/bin/touch /etc/squid/squid_passwd

#Ownership change
sudo chown proxy /etc/squid/squid_passwd

#htpassword set
/usr/bin/htpasswd -b -c /etc/squid/squid_passwd $squid_user $squid_password

#iptable port allow rule
/sbin/iptables -I INPUT -p tcp --dport 17361 -j ACCEPT
/sbin/iptables-save

echo $squid_user:$squid_password > /etc/squid/squid_login

#service restart
service squid restart
}


function Uninstallation(){
 echo -e '[*] Uninstalling SQUID Server'
 apt-get remove --purge squid &> /dev/null
 rm -rf /etc/squid*
 echo -e '[√] Squid3 Server successfully uninstalled and removed.'
}


clear
echo -e " Choose squid Proxy Installtion"
echo -e " [1] Install Squid"
echo -e " [2] Uninstall Squid"
until [[ "$opts" =~ ^[1-2]$ ]]; do
	read -rp " Choose from [1-2]: " -e opts
	done
	case $opts in

	1)
	Installation
	;;	
	2)
	Uninstallation
	exit 1
	;;
esac
exit 1
