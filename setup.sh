#!/bin/bash

# Quick Ubuntu VPS setup script. 

# Live long and prosper. 

# Before running create ssh key and add it to GitHub, else the private repos wont clone.
# ssh-keygen -t ed25519 -C "watergetnoenemy@github.com"

echo 'Installing...'
apt update -y
apt upgrade -y
apt install nginx -y
apt install certbot python3-certbot-nginx -y
debconf-set-selections <<< "postfix postfix/mailname string sammak.in"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix

echo 'Firewall...'
iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
iptables -I INPUT 6 -m state --state NEW -p tcp --dport 25 -j ACCEPT
netfilter-persistent save

echo 'Email...'
printf "\nvirtual_alias_domains = /etc/postfix/virtual_alias_domains" | tee -a /etc/postfix/main.cf
printf "\nvirtual_alias_maps = hash:/etc/postfix/virtual_alias_maps" | tee -a /etc/postfix/main.cf
printf "sammak.in" | tee /etc/postfix/virtual_alias_domains
printf "@sammak.in watergetnoenemy@gmail.com" | tee /etc/postfix/virtual_alias_maps
postmap /etc/postfix/virtual_alias_maps
systemctl restart postfix

echo 'Site setup...'
mkdir -p /var/www/sammak.in/html
chown -R $USER:$USER /var/www/sammak.in/html
chmod -R 755 /var/www/sammak.in
git clone --recurse-submodules git@github.com:SJMakin/site.git /var/www/sammak.in/html
echo 'server {
        listen 80;
        listen [::]:80;

        server_name sammak.in www.sammak.in;

        root /var/www/sammak.in/html;
        index index.html index.htm index.nginx-debian.html;

        location / {
                try_files $uri $uri/ =404;
        }

        error_page 404 /404/index.html;
        location  /404/index.html {
        internal;
        }

        error_page 403 /403/index.html;
        location  /403/index.html {
        internal;
        }
}' | tee /etc/nginx/sites-available/sammak.in
ln -s /etc/nginx/sites-available/sammak.in /etc/nginx/sites-enabled/
sed -i 's/# server_names_hash_bucket_size/server_names_hash_bucket_size/' /etc/nginx/nginx.conf

echo 'Verifying site setup...'
nginx -t
systemctl restart nginx

echo 'Lets Encrypt...'
certbot --nginx --redirect --non-interactive --agree-tos -m me@sammak.in -d sammak.in -d www.sammak.in
certbot renew --dry-run
