from flask import render_template, flash, redirect, url_for, request, send_file
from werkzeug.utils import secure_filename
import sys, os
from app import app
import threading

from app.tilehuria.polygon2mbtiles import polygon2mbtiles



def scandir(dir): 
    """Walk recursively through a directory and return a list of all files in it"""
    filelist = []
    for path, dirs, files in os.walk(dir):
        for f in files:
            filelist.append(os.path.join(path, f))
    return filelist

def task(**opts):
    infile = opts['infile']
    polygon2mbtiles(infile)

@app.route('/')
@app.route('/index')
def index():
    return render_template('index.html', title='Home')

@app.route('/upload', methods=['GET', 'POST'])
def upload():
    if request.method == 'POST':
        file = request.files['polygon']
        filename = secure_filename(file.filename)
        pathname = (os.path.join('files', filename))
        file.save(pathname)
        opts = {}
        opts ['infile'] = pathname
        print('\nHere are the options captured by the submit button:')
        print(opts)
        print('\n')

        # Crude threading to launch Tilehuria instead of a proper task queue
        threads = []
        thread = threading.Thread(target = task, kwargs = opts)
        thread.start()
        #polygon2mbtiles(opts)
        
        
        
        return render_template('upload.html', uploaded_file=filename)
    else:
        return render_template('index.html', title='No file. Try again!')

@app.route('/mbtiles')
def mbtiles():
    all_files = scandir('files')
    tilesets = []
    basenames = []
    for filename in all_files:
        (pathname, extension) = os.path.splitext(filename)
        basename = os.path.basename(filename)
        if extension == '.mbtiles':
            tilesets.append([basename, filename])
        
    return render_template('mbtiles.html', title='MBTiles for download',
                           tilesets = tilesets)

@app.route('/download_tileset/<path>')
def download_tileset(path):
    basename = os.path.basename(path)
    dirname = os.path.dirname(os.path.abspath(path))
    return send_file(os.path.join(dirname, 'files', basename), as_attachment = True)
