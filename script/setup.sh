#!/bin/bash

# Sets up a TileHuria server.
# Tested on a $10/month Digital Ocean droplet with Ubuntu 20.04
# installed.

# Assumes a non-root sudo user called tilehuria.

echo please enter the domain name of your TileHuria server
read domain_name
echo
echo Please enter an email address for certificate renewal information
read email
echo
echo Updating and upgrading the OS
sudo apt -y update
sudo apt -y upgrade

echo setting up a few random Python dependencies
sudo apt install -y build-essential libssl-dev libffi-dev python3-setuptools

echo setting up virtualenv and Flask infrastructure
sudo apt install -y python3-venv
sudo apt install -y python3-dev
python3 -m venv venv
source venv/bin/activate
pip install wheel
pip install flask
pip install uwsgi

echo installing GDAL and pygdal
sudo apt install -y libgdal-dev

# This will break; need to implement workaround below
#pip install pygdal==3.0.4.6

echo setting up python hooks for GDAL, pygdal.
echo Doing so via a horrible hack using a Python script to extract the latest
echo version of pygdal compatible with the specific GDAL installed. 
gdalversion=$(gdal-config --version)
echo $gdalversion
ERROR=$((pip install pygdal==$gdalversion) 2>&1)
echo $ERROR
python3 parse_pip_error.py "$ERROR" "$gdalversion"
pygdalversion=$(<pygdalversion.txt)
echo
echo installing pygdal version $pygdalversion
pip install pygdal==$pygdalversion
rm pygdalversion.txt


echo installing pillow Python Imaging Library fork
pip install pillow

echo installing SQLAlchemy because someday we will use it
pip install Flask-SQLAlchemy

echo installing dotenv for some reason
pip install python-dotenv

echo installing nginx
if ! type "nginx"; then
    sudo apt install -y nginx
else echo Nginx seems to be already installed
fi


echo adding the TileHuria site to nginx
cat > tilehuriaflask <<EOF
server {
    listen 80;
    server_name $domain_name www.$domain_name;

    location / {
        include uwsgi_params;
        uwsgi_pass unix:/home/tilehuria/tilehuria-flask/tilehuriaflask.sock;
    }
}
EOF

sudo mv tilehuriaflask /etc/nginx/sites-available/

echo creating symlink to tilehuriaflask site in nginx sites-enabled
if [ ! -f /etc/nginx/sites-enabled/tilehuriaflask ]; then
    sudo ln -s /etc/nginx/sites-available/tilehuriaflask /etc/nginx/sites-enabled
else echo Looks like the symlink has already been created
fi

echo installing Certbot
if ! type "certbot"; then
    sudo apt install -y certbot python3-certbot-nginx
else echo Certbot seems to be already installed
fi

echo Procuring a certificate for the site from LetsEncrypt using Certbot
sudo certbot --nginx -n --agree-tos --redirect -m $email -d $domain_name -d www.$domain_name


echo adding the TileHuria service to Systemd
cat > tilehuriaflask.service <<EOF
[Unit]
Description=uWSGI instance to serve tilehuriaflask
After=network.target

[Service]
User=tilehuria
Group=www-data
WorkingDirectory=/home/tilehuria/tilehuria-flask
Environment="PATH=/home/tilehuria/tilehuria-flask/venv/bin"
ExecStart=/home/tilehuria/tilehuria-flask/venv/bin/uwsgi --ini tilehuriaflask.ini

[Install]
WantedBy=multi-user.target
EOF

sudo mv tilehuriaflask.service /etc/systemd/system/

echo starting and enabling the TileHuria service with Systemd
sudo systemctl start tilehuriaflask.service
sudo systemctl enable tilehuriaflask.service

echo
echo ##################################################
echo NOW YOU NEED TO PROVIDE A URL_formats.txt FILE!!!!
echo ##################################################
