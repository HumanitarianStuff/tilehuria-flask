#!/bin/bash

# Sets up a tilehuria server.
# Tested on a $5/month Digital Ocean droplet with Ubuntu 18.04 installed.
# Assumes a non-root sudo user.

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
# now find the largest matching number in the string contained in the ERROR variable. Stick it in variable newgdalversion and use it in a repeat command
pip install pygdal==$newgdalversion

pip install pillow

