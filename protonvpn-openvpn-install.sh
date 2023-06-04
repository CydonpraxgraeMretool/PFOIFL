#!/bin/sh

#Variables
#Set /etc/openvpn/scripts to $OvpnS
OvpnS="/etc/openvpn/scripts"
#Set Version Number of update-systemd-resolved
RV="1.3.0"

#Install required packages
#pacman -S wget openvpn polkit

#Install update-systemd-resolved
mkdir $OvpnS
wget -P $OvpnS https://github.com/jonathanio/update-systemd-resolved/archive/refs/tags/v$RV.tar.gz &&
tar -xf $OvpnS/v$RV.tar.gz -C $OvpnS
#Move files to right folder and remove unecessary ones
rm -rf $OvpnS/{v$RV.tar.gz,update-systemd-resolved-$RV/{.gitignore,.travis.yml,CHANGELOG.md,LICENSE,Makefile,README,md}}
mv $OvpnS/update-systemd-resolved-$RV/* $OvpnS/
rm -rf $OvpnS/update-systemd-resolved-$RV
#Makes file executable
chmod +x $OvpnS/update-systemd-resolved
#Makes symlink so unmodified protonvpn.ovpn files don't have to be modified
ln -s /etc/openvpn/scripts/update-systemd-resolved /etc/openvpn/update-resolv-conf
#Create necessary config file
touch /etc/openvpn/client/client.conf
echo -e "client
remote example.com 1194 udp\n
script-security 2
setenv PATH /usr/bin
up /etc/openvpn/scripts/update-systemd-resolved
down /etc/openvpn/scripts/update-systemd-resolved
down-pre
dhcp-option DOMAIN-ROUTE ." >> /etc/openvpn/client/client.conf
touch /etc/polkit-1/rules.d/00-openvpn-resolved.rules
echo -e "polkit.addRule(function(action, subject) {
    if (action.id == 'org.freedesktop.resolve1.set-dns-servers' ||
        action.id == 'org.freedesktop.resolve1.set-domains' ||
        action.id == 'org.freedesktop.resolve1.set-dnssec') {
        if (subject.user == 'openvpn') {
            return polkit.Result.YES;
        }
    }
});" >> /etc/polkit-1/rules.d/00-openvpn-resolved.rules

#Informs user that install is finished
echo Install finished
