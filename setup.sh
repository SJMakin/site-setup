#!/bin/bash

# Quick Ubuntu VPS setup script. 

# Live long and prosper. 

# Before running create ssh key and add it to GitHub.
# ssh-keygen -t ed25519 -C "watergetnoenemy@github.com"

echo 'Installing...'
apt update -y
apt upgrade -y
apt install nginx -y
apt install certbot python3-certbot-nginx -y

echo 'Firewall...'
iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
netfilter-persistent save

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
