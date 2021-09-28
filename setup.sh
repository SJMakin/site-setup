#!/bin/bash

# Quick Ubuntu VPS setup script. 

# Live long and prosper. 

# Before running create ssh key and add it to GitHub.
# ssh-keygen -t ed25519 -C "watergetnoenemy@github.com"

echo 'Installing...'
sudo apt update -y
sudo apt upgrade -y
sudo apt install nginx -y
sudo apt install certbot python3-certbot-nginx -y

echo 'Firewall...'
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save

echo 'Site setup...'
sudo mkdir -p /var/www/sammak.in/html
sudo chown -R $USER:$USER /var/www/sammak.in/html
sudo chmod -R 755 /var/www/sammak.in
sudo git clone --recurse-submodules git@github.com:SJMakin/site.git /var/www/sammak.in/html
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
}' | sudo tee /etc/nginx/sites-available/sammak.in
sudo ln -s /etc/nginx/sites-available/sammak.in /etc/nginx/sites-enabled/
sudo sed -i 's/# server_names_hash_bucket_size/server_names_hash_bucket_size/' /etc/nginx/nginx.conf

echo 'Verifying site setup...'
sudo nginx -t
sudo systemctl restart nginx

echo 'Lets Encrypt...'
sudo certbot --nginx --redirect --non-interactive --agree-tos -m me@sammak.in -d sammak.in -d www.sammak.in
sudo certbot renew --dry-run