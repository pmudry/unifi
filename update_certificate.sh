#!/bin/bash
# Author: Frank Gabriel, 01.01.2019
# Credits Kalle Lilja, @SprockTech and others
# Script location: /etc/letsencrypt/renewal-hooks/post/unifi-import-cert.sh (important for auto renewal)
# Tested with Debian 9 and UniFi 5.8.28, 5.9.22 and 5.9.32 - should work with any recent Unifi and Ubuntu/Debian releases

#************************************************
#******************Instructions******************
#************************************************

#0
# Make sure file is in Linux format (windows=cr/lf, linux=lf)
# Configure your firewall, hostname, hosts, ntp and TZ data (out of scope here)
# sudo for all commands if you are not root

#1
# Install/upgrade unifi controller and dependencies: (for 5.9.22, for other releases get url from Unifi release note)
# wget https://dl.ubnt.com/unifi/5.9.22-d2a4718971/unifi_sysvinit_all.deb 
# Use "apt install" instead of "dpkg -i" to automatically install dependencies
# apt install ./unifi_sysvinit_all.deb 

#2
# Get a certificate, run the following shell commands: (installs certbot-auto components and runs an interactive dialogue)
# wget https://dl.eff.org/certbot-auto
# chmod a+x ./certbot-auto
# ./certbot-auto certonly 

#3
# Get the import script and import the certificate: 
# wget https://util.wifi.gl/unifi-import-cert.sh 
# cp ./unifi-import-cert.sh /etc/letsencrypt/renewal-hooks/post/
# chmod a+x /etc/letsencrypt/renewal-hooks/post/unifi-import-cert.sh

#4 Run the import script
# /etc/letsencrypt/renewal-hooks/post/unifi-import-cert.sh

#5
# Renew a certificate: (include as a monthly cron job, The certbot-auto post-hook will automatically execute the import script upon renewal)
# ./certbot-auto renew 

#************************************************
#********************Script**********************
#************************************************

# Set the Domain name, valid DNS entry must exist
# DOMAIN="yourdomain.com"
# To automatically detect DOMAIN (thanks to @SprockTech):
DOMAIN=$(mongo --quiet --port 27117 --eval 'db.getSiblingDB("ace").setting.find({"key": "super_identity"}).forEach(function(document){ print(document.hostname) })')

# Backup previous keystore
cp /var/lib/unifi/keystore /var/lib/unifi/keystore.backup.$(date +%F_%R)

# Convert cert to PKCS12 format
# Ignore warnings
openssl pkcs12 -export -inkey /etc/letsencrypt/live/${DOMAIN}/privkey.pem -in /etc/letsencrypt/live/${DOMAIN}/fullchain.pem -out /etc/letsencrypt/live/${DOMAIN}/fullchain.p12 -name unifi -password pass:unifi

# Install certificate
# Ignore warnings
keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /var/lib/unifi/keystore -srckeystore /etc/letsencrypt/live/${DOMAIN}/fullchain.p12 -srcstoretype PKCS12 -srcstorepass unifi -alias unifi -noprompt

#Restart UniFi controller
service unifi restart


