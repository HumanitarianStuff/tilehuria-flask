# Server for TileHuria

Basic instructions for setting up a TileHuria server using Flask.

A lot of this is fairly directly taken from the DigitalOcean community tutorial https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-uswgi-and-nginx-on-ubuntu-18-04.

## Create and set up a server

Create a cloud server (Ubuntu 18.04) and a sudo user. The usual setup from https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-18-04. Log in.

## Set up a bunch of python stuff

```
sudo apt install -y python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools
```

## Install the Tilehuria-Flask folder
```
git clone https://github.com/ivangayton/tilehuria-flask
cd tilehuria/
```

#### Install the actual tilehuria code inside the app folder

```
cd app
git clone https://github.com/humanitarianstuff/tilehuria
cd ../
```

#### Set up a virtualenv and the basic infrastructure of Flask

```
sudo apt install -y python3-venv
python3 -m venv venv
source venv/bin/activate
pip install wheel
pip install uwsgi flask
```

## install GDAL in your venv
Discussion of this task, which seems way more complicated than it should be, can be found here (where I found a way to accomplish it): https://stackoverflow.com/questions/32066828/install-gdal-in-virtualenvwrapper-environment

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

## Maybe it's useful to install dotenv?

I dunno. At some point I'll try without doing this, but haven't gotten around to it and no idea what will happen without it.
```
pip install python-dotenv
```

## Test it using the Flask dev server

If you want to confirm that things are working thus far, you can run the Flask development server and connect to it from your browser at tilehuria.org:5000 (or whatever your actual URL is). To run the server type:
```
flask run --host=0.0.0.0
```
and control-C to stop it.

## Test it using the uWSGI server

You can also try it using the uWSGI server running from the command line. This assumes that the various bits of setup are correctly configured; the Github may have some hard-coded stuff in the Flask-related files specific to the tilehuria.org URL.

```
uwsgi --socket 0.0.0.0:5000 --protocol=http -w wsgi:app
```
Again, try connecting to it from your browser, and when done testing control-C to stop it. 

## Create a service and start it up
bung the following into ```/etc/systemd/system/tilehuriaflask.service```

```
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

```

Now start and enable the service by:
```
sudo systemctl start tilehuriaflask.service
sudo systemctl enable tilehuriaflask.service
```

If you want to test that this worked, enter ```sudo systemctl status tilehuriaflask.service```

## Install Nginx

```
sudo apt install nginx
```

## Configure Nginx to serve the app

Enter the following into ```/etc/nginx/sites-available/tilehuriaflask```:


```
server {
    listen 80;
    server_name tilehuria.org www.tilehuria.org;

    location / {
        include uwsgi_params;
        uwsgi_pass unix:/home/tilehuria/tilehuria-flask/tilehuriaflask.sock;
    }
}
```

and symlink it to the sites-enabled by typing```sudo ln -s /etc/nginx/sites-available/tilehuriaflask /etc/nginx/sites-enabled```

# Secure the whole damned thing with LetsEncrypt
```
sudo add-apt-repository ppa:certbot/certbot
sudo apt install python-certbot-nginx
sudo certbot --nginx -d tilehuria.org -d www.tilehuria.org
```