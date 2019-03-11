#!/bin/bash

# Sets up a tilehuria server.
# Tested on a $5/month Digital Ocean droplet with Ubuntu 18.04 installed.
# Assumes a non-root sudo user.

sudo apt -y update
sudo apt -y upgrade

sudo apt install -y python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools

git clone https://github.com/HumanitarianStuff/tilehuria-flask
cd tilehuria-flask/

cd app
git clone https://github.com/HumanitarianStuff/tilehuria
cd ../

sudo apt install -y python3-venv
python3 -m venv venv
source venv/bin/activate
pip install wheel
pip install uwsgi flask


deactivate
sudo apt install libgdal-dev

source venv/bin/activate
gdalversion=$(gdal-config --version)
ERROR=((pip install pygdal==$gdalversion) 2>&1)
echo $ERROR
# TODO: now find the largest matching number in the string contained in the ERROR variable. Stick it in variable newgdalversion and use it in a repeat command
pip install pygdal==$newgdalversion

pip install pillow

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

sudo systemctl start tilehuriaflask.service
sudo systemctl enable tilehuriaflask.service

sudo apt install -y nginx

cat > /etc/nginx/sites-available/tilehuriaflask <<EOF
server {
    listen 80;
    server_name tilehuria.org www.tilehuria.org;

    location / {
        include uwsgi_params;
        uwsgi_pass unix:/home/tilehuria/tilehuria-flask/tilehuriaflask.sock;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/tilehuriaflask /etc/nginx/sites-enabled

# TODO Add the -y flag to the following command (if that's how that works)
sudo add-apt-repository ppa:certbot/certbot

sudo apt install -y python-certbot-nginx

# TODO use the silent version of the certbot command
# correctly set up email (ask at beginning of script),
# agreements (yes to license, no by default for email news),
# and redirect (option 2, redirect)
sudo certbot --nginx -d tilehuria.org -d www.tilehuria.org
