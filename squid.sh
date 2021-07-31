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
/usr/bin/wget https://raw.githubusercontent.com/avinashkraghu-3/sockes5-squid-bash/main/squid-1.conf -O /etc/squid/squid-1.conf

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
