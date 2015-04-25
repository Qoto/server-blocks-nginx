#!/bin/bash

DOMAIN=$1
ROOT_DIR="/var/www/$DOMAIN/public"
BLOCK="/etc/nginx/sites-available/$DOMAIN"

php -v > /dev/null 2>&1 || { 
  printf "====== PHP is not installed. Instalation Aborted! ======\n"; 
  exit 0; 
}

# Test if HipHop is installed
hhvm --version > /dev/null 2>&1
HHVM_IS_INSTALLED=$?

# Test if Nginx is installed
nginx -v > /dev/null 2>&1
NGINX_IS_INSTALLED=$?

echo ">>> Installing $DOMAIN"

# Create the Document Root directory
sudo mkdir -p $ROOT_DIR

# Assign ownership to user account
# sudo chown -R $USER:$USER $ROOT_DIR

# Create the Nginx server block file:
sudo tee $block > /dev/null <<EOF 
server {
  # don't forget to tell on which port this server listens
  listen [::]:80;
  listen 80;

  # listen on the www host
  server_name www.$DOMAIN;

  # and redirect to the non-www host (declared below)
  return 301 \$scheme://$DOMAIN\$request_uri;
}

server {
  # listen 80 deferred; # for Linux
  # listen 80 accept_filter=httpready; # for FreeBSD
  listen [::]:80;
  listen 80;

  # The host name to respond to
  server_name $DOMAIN;
  
  # Work With FastCGI
  location ~ \\.(hh|php)\$ {
    fastcgi_keep_conn on;
    fastcgi_pass   127.0.0.1:9000;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include        fastcgi_params;
  }

  # Path for static files
  root /var/www/$DOMAIN/public;

  #Specify a charset
  charset utf-8;

  # Custom 404 page
  error_page 404 /404.html;

  # Include the basic h5bp config set
  include h5bp/basic.conf;
}


EOF

# Link to make it available
sudo ln -s $BLOCK /etc/nginx/sites-enabled/

# Test configuration and reload if successful
sudo nginx -t && sudo service nginx reload
