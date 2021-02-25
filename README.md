# Server for TileHuria

Basic instructions for setting up a TileHuria server using Flask.

A lot of this is fairly directly taken from the DigitalOcean community tutorial https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-uswgi-and-nginx-on-ubuntu-18-04.

## Create and set up a server

Create a cloud server (Ubuntu 20.04) and a sudo user. The usual setup from https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-20-04. Log in.


### Install the Tilehuria-Flask directory

```
git clone https://github.com/HumanitarianStuff/tilehuria-flask
cd tilehuria-flask/
```

#### Persuade Git to pull down the code from the tilehuria utility

```
git submodule update
```

#### Add URLs to the tileservers you wish to use in the URL_formats.txt file
TileHuria downloads tiles from servers; many of these may be commercial and subject to terms of service which do not permit downloading for every type of endeavor. Please see the [TileHuria Appropriate Use policy](https://github.com/HumanitarianStuff/tilehuria#appropriate-use-dos-and-donts) for more details. The bottom line is: we can't provide you with a bunch of URLs that link directly to commercial tile servers. You'll have to enter your own. 

A good source of tileserver URLs is [JOSM](https://josm.openstreetmap.de/). Install JOSM, go to the Imagery Preferences, and a number of tile URLs appropriate for humanitarian mapping use are visible.

The URL_formats.txt file in the app/tilehuria/tilehuria/ directory) contains two links, both to OpenStreetMap tileservers. **Please do not abuse these; they are a public service provided by the non-profit OpenStreetMap, and should be used sparingly.** The URLs are formatted as in the following examples:

```
myservername https://mytileserver.com/{zoom}/{x}/{y}.png?access_token=mytoken
anotherservername http://{switch:a,b,c,d}.tiles.atmyserver.org/{zoom}/{x}/{y}
```

This is a flat text file with no formatting, headers, or anything. Note that on each line there is a name, a space, then a URL (the name will be used to populate the dropdown for each user's available tileservers). Each URL contains variables contained in {curly braces}; these are replaced for each individual tile with the appropriate values. TileHuria will work with almost any SlippyMap compliant tileserver, it's just a matter of getting the URL right.

If you are doing work with humanitarian mapping and need help with this, get in touch with Ivan Gayton at the Humanitarian OpenStreetMap Team; if your cause is worthy and we're confident that you aren't going to abuse the trust of imagery providers we may be able to assist you.


# The easy way
In the script directory, there is a setup script that, if everything is perfect, will install the Tilehuria web app.

```
sudo script/setup.sh
```

# The Hard Way
If that didn't work (shocker), here are the steps to install.

### Set up a virtualenv and the basic infrastructure of Flask

```
sudo apt install -y python3-venv
sudo apt install -y python3-dev
python3 -m venv venv
source venv/bin/activate
pip install wheel
pip install flask
pip install uwsgi
```

#### install GDAL
Discussion of this task, which seems way more complicated than it should be, can be found here (where I found a way to accomplish it): https://stackoverflow.com/questions/32066828/install-gdal-in-virtualenvwrapper-environment
first the gdal library itself:

```
sudo apt install libgdal-dev
```

Then the pygdal hooks:
```
gdalversion=$(gdal-config --version)
pip install pygdal==$gdalversion
```

That'll probably give you an error, so you look at the error output and add the latest version (i.e. ```pip install pygdal==2.2.3.3```). Or replace the previous block with the following (unfinished block):

```
source venv/bin/activate
gdalversion=$(gdal-config --version)
ERROR=((pip install pygdal==$gdalversion) 2>&1)
echo $ERROR
# now find the largest matching number in the string contained in the ERROR variable. Stick it in variable newgdalversion and use it in a repeat command
pip install pygdal==$newgdalversion
```

At time of writing that produces ```pip install pygdal==3.0.4.6```.

## Install the imaging library

```
pip install pillow
```

### SQLAlchemy for when I get login and signup working
```
pip install Flask-SQLAlchemy
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

The uWSGI server is really useful because there isn't any logging, error checking, or anything working yet. When running as a service, there's no obvious way to troubleshoot. On the uWSGI server, you'll see command line output including error message.

```
uwsgi --socket 0.0.0.0:5000 --protocol=http -w wsgi:app
```
Again, try connecting to it from your browser, and when done testing control-C to stop it. 

## Create a service and start it up
bung the following into ```/etc/systemd/system/tilehuriaflask.service``` (this file is actually provided in the repo, so you can just copy it over ```sudo cp tilehuriaflask.service /etc/systemd/system/```

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

Enter the following into ```/etc/nginx/sites-available/tilehuriaflask``` (again, file provided, just ```sudo cp tilehuriaflask /etc/sites-available/```:


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
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d tilehuria.org -d www.tilehuria.org
```

It should work now.