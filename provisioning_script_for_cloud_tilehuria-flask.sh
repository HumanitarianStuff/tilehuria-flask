#!/bin/bash -eu

# Sets up a TileHuria server.
# Tested on a $5/month Digital Ocean droplet with Ubuntu 20.04
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
    sudo add-apt-repository -y ppa:certbot/certbot
    sudo apt install -y python-certbot-nginx
else echo Certbot seems to be already installed
fi

echo Procuring a certificate for the site from LetsEncrypt using Certbot
sudo certbot --nginx -n --agree-tos --redirect -m $email -d $domain_name -d www.$domain_name

echo setting up a bunch of Python dependencies
sudo apt install -y python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools

echo collecting TileHuria
cd app
if [ ! -d tilehuria ]; then  
    git clone https://github.com/HumanitarianStuff/tilehuria
else git pull
fi
cd ../

echo setting up GDAL. 

if [[ "$response" =~ ^(yes|y)$ ]]; then
    echo Adding UbuntuGIS repository for recent version of GDAL
    sudo apt install -y python-software-properties
    sudo add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 314DF160
    sudo apt update
fi

sudo apt install -y libgdal-dev

echo setting up a Python3 virtual environment
sudo apt install -y python3-venv
python3 -m venv venv
source venv/bin/activate

echo setting up uwsgi and flask
pip install wheel
pip install uwsgi flask

echo setting up python hooks for GDAL, pygdal.
echo Doing so via a horrible hack using a Python script to extract the latest
echo version of pygdal compatible with the specific GDAL installed. 
gdalversion=$(gdal-config --version)
ERROR=$((pip install pygdal==$gdalversion) 2>&1)
echo $ERROR
python3 parse_pip_error.py "$ERROR" "$gdalversion"
pygdalversion=$(<gdalversion.txt)
echo
echo So we are installing pygdal version $pygdalversion
pip install pygdal==$pygdalversion
rm pygdalversion.txt

echo installing the Pillow imaging library
pip install pillow

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
