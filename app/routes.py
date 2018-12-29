from flask import render_template, flash, redirect, url_for, request, send_file
from werkzeug.utils import secure_filename
import sys, os
from app import app
import threading

from app.tilehuria.tilehuria.polygon2mbtiles import polygon2mbtiles

def scandir(dir): 
    """Walk recursively through a directory and return a list of all files in it"""
    filelist = []
    for path, dirs, files in os.walk(dir):
        for f in files:
            filelist.append(os.path.join(path, f))
    return filelist

def cleanopts(optsin):
    """Takes a multidict from a a flask form and returns cleaned dict of options"""
    opts = {}
    d = optsin
    for key in d:
        opts[key] = optsin[key].lower().replace(' ', '_')
    return opts
    
def task(**opts):
    """Launches a thread to create an MBTile set in a background process"""
    infile = opts['infile']
    polygon2mbtiles(infile, opts)

@app.route('/')
@app.route('/index')
def index():
    return render_template('index.html', title='Home')

@app.route('/upload', methods=['GET', 'POST'])
def upload():
    if request.method == 'POST':
        infile = request.files['polygon']
        choices = request.form
        opts = cleanopts(choices)
        filename = secure_filename(infile.filename)
        pathname = (os.path.join('files', filename))
        infile.save(pathname)
        opts['infile'] = pathname
        print('\nOptions captured by the submission:')
        print(opts)
        print('\n')

        # Crude threading to launch Tilehuria instead of a proper task queue
        threads = []
        thread = threading.Thread(target = task, kwargs = opts)
        thread.start()
        
        return render_template('upload.html', uploaded_file=filename)
    else:
        return render_template('index.html', title='No file. Try again!')

@app.route('/mbtiles')
def mbtiles():
    all_files = scandir('files')
    tilesets = []
    aois = []
    for filename in all_files:
        (pathname, extension) = os.path.splitext(filename)
        basename = os.path.basename(filename)
        if extension.lower() == '.mbtiles':
            tilesets.append((basename, filename))
        if extension.lower() == '.geojson':
            if pathname[-10 :] != 'perimeters':
                aois.append((basename, filename))
            
        
    return render_template('mbtiles.html', title='MBTiles for download',
                           tilesets = tilesets,
                           aois = aois)

@app.route('/download_tileset/<path>')
def download_tileset(path):
    basename = os.path.basename(path)
    dirname = os.path.dirname(os.path.abspath(path))
    return send_file(os.path.join(dirname, 'files', basename), as_attachment = True)
