# Server for TileHuria

Basic instructions for setting up a TileHuria server using Flask.

A lot of this is fairly directly taken from the DigitalOcean community tutorial https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-uswgi-and-nginx-on-ubuntu-18-04.

## Create and set up a server

Create a cloud server (Ubuntu 18.04) and a sudo user. The usual setup from https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-18-04. Log in.

## Set up a bunch of python stuff

```
sudo apt install -y python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools
```

### Install the Tilehuria-Flask folder

```
git clone https://github.com/HumanitarianStuff/tilehuria-flask
cd tilehuria-flask/
```

#### Install the tilehuria code inside the app folder

```
cd app
git clone https://github.com/HumanitarianStuff/tilehuria
cd ../
```

#### Add the URL_formats.txt file to the Tilehuria folder
TileHuria downloads tiles from servers; many of these may be commercial and subject to terms of service which do not permit downloading for every type of endeavor. Please see the [TileHuria Appropriate Use policy](https://github.com/HumanitarianStuff/tilehuria#appropriate-use-dos-and-donts) for more details. The bottom line is: we can't provide you with a bunch of URLs that link directly to tile servers. You'll have to enter your own.

A good source of tileserver URLs is [JOSM](https://josm.openstreetmap.de/). Install JOSM, go to the Imagery Preferences, and a number of tile URLs appropriate for humanitarian mapping use are visible.

The URL_formats.txt file (which must be named exactly that, and should be placed in the app/tilehuria/tilehuria/ directory) is formatted as in the following examples:

```
myservername https://mytileserver.com/{zoom}/{x}/{y}.png?access_token=mytoken
anotherservername http://{switch:a,b,c,d}.tiles.atmyserver.org/{zoom}/{x}/{y}
```

This is a flat text file with no formatting, headers, or anything. Note that on each line there is a name, a space, then a URL (the name will be used to populate the dropdown for each user's available tileservers). Each URL contains variables contained in {curly braces}; these are replaced for each individual tile with the appropriate values. TileHuria will work with almost any SlippyMap compliant tileserver, it's just a matter of getting the URL right.

### Set up a virtualenv and the basic infrastructure of Flask

#### install GDAL
Discussion of this task, which seems way more complicated than it should be, can be found here (where I found a way to accomplish it): https://stackoverflow.com/questions/32066828/install-gdal-in-virtualenvwrapper-environment
first the gdal library itself:

```
sudo apt install libgdal-dev
```

#### TODO: this installs quite an old version of GDAL. Maybe use the ubuntugis PPA?

Now the virtual environment:
```
sudo apt install -y python3-venv
python3 -m venv venv
source venv/bin/activate
pip install wheel
pip install uwsgi flask
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

# TODO for devs

## Critical (in rough order of importance)

- Ideally each user would have their own URL list saved. This would require implementing users, logins, etc.
  - Use the [Flask login library](https://flask-login.readthedocs.io/en/latest/)
  - Provide a page for users to enter their custom URLs, which will be stored in their very own URL_formats.txt files (or database tables).
  - Provide a single login per humanitarian org that needs Tilehuria and has agreed to abide the the various tile providers' terms of service. 
- TileHuria-Flask doesn't provide users any insight into errors with their AOI files (or any other errors for that matter). There's a stubbed-in Status column in the MBTiles screen, but it doesn't currently say anything.
  - Current idea is to save an error log file for each upload and link to that in the Error column.
  - This should be implemented using the [python Logging facility](https://docs.python.org/3/library/logging.html), which in any case [flask uses](http://flask.pocoo.org/docs/1.0/logging/) by default.
- The Delete button should probably actually do something
- There should be an error and/or warning when someone attempts to create too large an MBTile.
  - Either fetch the area of the AOI using GDAL and calculate the number of tiles given the requested zoom levels, or
  - Just run the create_csv script and count the tiles. This will still be problematic if someone attempts to generate a CSV with a high zoom level for a whole country&mdash;the script will stall or maybe even run out of memory&mdash;but in most circumstances it'll be simpler and more accurate (for one thing, it'll give a precise estimate of the number of tiles that will be generated).

## Nice to have
- Currently to generate multiple MBTile sets from one AOI you just upload the same thing multiple times. This, of course, leaves open the possibility of different AOIs with the same name (prediction: many versions of test.geojson).
  - Ideally check for an identically-named file (maybe even check if it's the same file byte-for-byte) and offer to either use the already-uploaded one with different settings or rename.
  - In this case, we should re-think the naming scheme to account for more than just tileserver.
- Implement an adaptive concurrent download strategy to account for varying internet speeds.
  - The current threaded downloading works fine on the cloud server (defaults to 50 threads downloading concurrently, which seems to be about right), but running locally in an area with slow internet often results in timed-out tiles.
  - Ping suggested http://docs.python-requests.org/en/master/
- Allow for direct serving of tiles from the cloud server.
  - The tiles are already downloaded onto the server. It would be handy to have them instantly available for a mapathon.
  - This would be particularly useful if someone is planning a mapathon and preps a POSM-style server beforehand (or even in a high-bandwidth country prior to traveling to a low-bandwidth place). In some cases serving tiles on a LAN might be preferable to distributing MBTiles on removable media.
- Nice to get a Pip install working.
