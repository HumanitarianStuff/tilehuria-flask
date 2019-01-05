# Server for TileHuria

Basic instructions for setting up a TileHuria server using Flask.

A lot of this is fairly directly taken from the DigitalOcean community tutorial https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-uswgi-and-nginx-on-ubuntu-18-04.

## Create and set up a server

Create a cloud server (Ubuntu 18.04) and a sudo user. The usual setup from https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-18-04. Log in.

## Set up a bunch of python stuff

```
sudo apt install -y python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools
```

## Install the Tilehuria-Flask folder and switch to the working branch

```
git clone https://github.com/HumanitarianStuff/tilehuria-flask
cd tilehuria/
git checkout dev
```

#### Install the tilehuria code inside the app folder and switch to the working branch

```
cd app
git clone https://github.com/HumanitarianStuff/tilehuria
git checkout forflask
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

- Implement the URL parsing so users supply their own URLs and API keys.
  - Currently several commercial tile provider URLs are hard-coded. Get rid of this! Allow users to paste a URL (JOSM-style) and allow TileHuria to substitute in the ZXY, switch-server, and quadkey components without itself knowing any URLs or API keys.
  - Ideally each user would have their own URL list saved. This would require implementing users, logins, etc&mdash;this is firmly in nice-to-have territory&mdash;the immediate imperative is simply to implement URL pasting.
- Need to either get GDAL working better, or get rid of it and use Shapely.
  - The Python version of GDAL seems to be choking on GeoJSON files not generated from scratch (taking a polygon shapefile and saving it in QGIS as GeoJSON seems to result in a perfectly workable GeoJSON file that nevertheless the OGR driver rejects).
  - Even more bizarrely, the GeoJSON generated by TileHuria itself (therefore generated by the Python GDAL driver) are rejected by the very same driver.
- Need to get a Pip install working, or sort the imports.
  - Standalone TileHuria works using uncomplicated imports (polygon2mbtiles imports the other scripts simply by name). Flask tilehuria, which calls polygon2mbtiles from an upstream directory, only works if imports are dotted to make them relative.
  - A Pip install would presumably fix that, as would some kind of addition to the python path, or perhaps horrible conditional logic importing one way if called from its own folder and the other way if called from elsewhere. Either way, yuck.
- TileHuria-Flask doesn't provide users any insight into errors with their AOI files (or any other errors for that matter). There's a stubbed-in Status column in the MBTiles screen, but it doesn't currently say anything.
  - Current idea is to save some kind of error log file for each upload and link to that in the Error column.
- The Delete button should probably actually do something
- There should be an error and/or warning when someone attempts to create too large an MBTile.
  - Either fetch the area of the AOI using GDAL and calculate the number of tiles given the requested zoom levels, or
  - Just run the create_csv script and count the tiles. This will still be problematic if someone attempts to generate a CSV with a high zoom level for a whole country&mdash;the script will stall or maybe even run out of memory&mdash;but in most circumstances it'll be simpler and more accurate (for one thing, it'll give a precise estimate of the number of tiles that will be generated).


## Nice to have
- Clean up the main function in create_tile_list.
  - This has a lot of spaghetti in it. In particular, there's a shitload of math right in the body of the main function which should be farmed out to separate functions (maybe even contained in a separate utils.py module. In any case, the following things should be handled separately rather than all mixed together:
    - Loading the driver and polygons
    - Figuring out the extents and kicking out tiles not in the AOI Polygon(s)
    - Calculating the extents and URLs of each tile
    - Writing the outputs (CSV and GIS file)
  - Currently to generate multiple MBTile sets from one AOI you just upload the same thing multiple times. This, of course, leaves open the possibility of different AOIs with the same name (prediction: many versions of test.geojson).
  - Ideally check for an identically-named file (maybe even check if it's the same file byte-for-byte) and offer to either use the already-uploaded one with different settings or rename.
  - In this case, we should re-think the naming scheme to account for more than just tileserver.
- Logins for individual users who can save their preferences (mainly URLs).
  - If TileHuria integrates with Tasking Manager, that may solve the login problem by piggybacking on TM logins.
- Implement an adaptive concurrent download strategy to account for varying internet speeds.
  - The current threaded downloading works fine on the cloud server (defaults to 50 threads downloading concurrently, which seems to be about right), but running locally in an area with slow internet often results in timed-out tiles.
  - Ping suggested http://docs.python-requests.org/en/master/
- Allow for direct serving of tiles from the cloud server.
  - The tiles are already downloaded onto the server. It would be handy to have them instantly available for a mapathon.
  - This would be particularly useful if someone is planning a mapathon and preps a POSM-style server beforehand (or even in a high-bandwidth country prior to traveling to a low-bandwidth place). In some cases serving tiles on a LAN might be preferable to distributing MBTiles on removable media.

