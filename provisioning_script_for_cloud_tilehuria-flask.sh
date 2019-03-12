#!/bin/bash -eu

# Sets up a TileHuria server.
# Tested on a $5/month Digital Ocean droplet with Ubuntu 18.04 installed.
# Assumes a non-root sudo user.

echo please enter the domain name of your TileHuria server
read domain_name
echo
echo Please enter an email address for certificate renewal information (certbot)
read email
echo
echo Updating and upgrading the OS
sudo apt -y update
sudo apt -y upgrade

echo installing nginx
sudo apt install -y nginx

echo adding the TileHuria site to nginx
cat > /etc/nginx/sites-available/tilehuriaflask <<EOF
server {
    listen 80;
    server_name $domain_name www.$domain_name;

    location / {
        include uwsgi_params;
        uwsgi_pass unix:/home/tilehuria/tilehuria-flask/tilehuriaflask.sock;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/tilehuriaflask /etc/nginx/sites-enabled

echo installing Certbot
# TODO Add the -y flag to the following command (if that's how that works)
sudo add-apt-repository ppa:certbot/certbot
sudo apt install -y python-certbot-nginx
echo Procuring a certificate for the site from LetsEncrypt using Certbot
sudo certbot --nginx -n --agree-tos --redirect -m $email -d $domain_name -d www.$domain_name

echo setting up a bunch of Python dependencies
sudo apt install -y python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools

echo collecting TileHuria
git clone https://github.com/HumanitarianStuff/tilehuria-flask
cd tilehuria-flask/

cd app
git clone https://github.com/HumanitarianStuff/tilehuria
cd ../

echo setting up GDAL (still an old version; maybe gonna use a PPA for this)
sudo apt install libgdal-dev

echo setting up a Python3 virtual environment
sudo apt install -y python3-venv
python3 -m venv venv
source venv/bin/activate

echo setting up uwsgi and flask
pip install wheel
pip install uwsgi flask

echo setting up python hooks for GDAL (currently this fails - to fix)
gdalversion=$(gdal-config --version)
ERROR=((pip install pygdal==$gdalversion) 2>&1)
echo $ERROR
# TODO: now find the largest matching number in the string contained in the ERROR variable. Stick it in variable newgdalversion and use it in a repeat command
pip install pygdal==$newgdalversion

echo installin the Pillow imaging library
pip install pillow

echo adding the TileHuria service to Systemd
cat > /etc/systemd/system/tilehuriaflask.service <<EOF
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

echo starting and enabling the TileHuria service with Systemd
sudo systemctl start tilehuriaflask.service
sudo systemctl enable tilehuriaflask.service


