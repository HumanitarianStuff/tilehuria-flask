# Server for TileHuria

## Installation

- Create a cloud server (Ubuntu 18.04) and a sudo user. Log in.
- Set up a bunch of python stuff like this: https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-uswgi-and-nginx-on-ubuntu-18-04

```
sudo apt update
sudo apt -y upgrade
sudo apt install -y python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools
```

## Install the Tilehuria-Flask folder
```
git clone https://github.com/ivangayton/tilehuria-flask
cd tilehuria/
```

- Install the actual tilehuria code inside the app folder

```
cd app
git clone https://github.com/humanitarianstuff/tilehuria
cd ../
```
- Set up a virtualenv and the basic infrastructure of Flask

```
sudo apt install -y python3-venv
python3 -m venv venv
source venv/bin/activate
pip install wheel
pip install uwsgi flask


```

## install GDAL (a bit of a trial in a venv)
Instructons for this rather unpleasant task can be found here: https://stackoverflow.com/questions/32066828/install-gdal-in-virtualenvwrapper-environment

```
deactivate
sudo apt install libgdal-dev
source venv/bin/activate
gdalversion=$(gdal-config --version)
pip install pygdal==$gdalvers
```

That'll probably give you an error, so you look at the error output and add the latest version (i.e. ```pip install pygdal==2.2.3.3```

#### TODO: Write a function that parses the error output and automatically adds the final version number digit to the above command

## Install the imaging library

```
pip install pillow
```

## Create a service
bung the following into ```/etc/systemd/system/tilehuriaflask.service```

```
[Unit]
Description=uWSGI instance to serve tilehuriaflask
After=network.target

[Service]
User=tilehuria
Group=www-data
WorkingDirectory=/home/tilehuria/tilehuria-flask
Environment="PATH=/home/tilehuria/tilehuria-flask/"
ExecStart=/home/tilehuria/tilehuria-flask/venv/bin/uwsgi --ini tilehuriaflask.ini

[Install]
WantedBy=multi-user.target

```

## Install nginx

```sudo apt install nginx```
