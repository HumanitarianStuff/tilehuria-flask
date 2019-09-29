from flask import render_template, flash, redirect, url_for, request, send_file
# for login
from flask import session, abort
from werkzeug.utils import secure_filename
import sys, os
from app import app
import threading

from app.tilehuria.tilehuria.polygon2mbtiles import polygon2mbtiles
from app.tilehuria.tilehuria.utils import get_url_name_list

from . import db


def scandir(dir): 
    """Walk recursively through a directory and return a list of all files in it"""
    filelist = []
    for path, dirs, files in os.walk(dir):
        for f in files:
            filelist.append(os.path.join(path, f))
    return filelist

def scandirnorecurse(dir):
    """Walk non-recursively through a directory and return a list of files in it"""
    filelist = []
    for path, dirs, files in os.walk(dir):
        for f in files:
            filelist.append(os.path.join(path, f))
        break    # Restricts it to the top-level directory; remove to recurse
    return filelist
    

def cleanopts(optsin):
    """Takes a multidict from a flask form, returns cleaned dict of options"""
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
    """Home page where users are invited to upload an AOI and select optionse"""
    # Get the available tileservers
    sn = get_url_name_list()
    return render_template('index.html', title='Home', servernames = sn)

@app.route('/upload', methods=['GET', 'POST'])
def upload():
    if request.method == 'POST':
        infile = request.files['polygon']
        choices = request.form
        opts = cleanopts(choices)
        filename = secure_filename(infile.filename)
        if not os.path.exists('files'):
            outdir = os.makedirs('files')
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
    all_files = scandirnorecurse('files')
    aois = []
    for filename in all_files:
        (pathname, extension) = os.path.splitext(filename)
        basename = os.path.basename(filename)
        stripped_name = os.path.splitext(basename)[0]
        namelen = len(stripped_name)
        if extension.lower() == '.geojson':
            if pathname[-10 :] != 'perimeters':
                tilesets = []
                for filen in all_files:
                    (pathn, exten) = os.path.splitext(filen)
                    mbtilefilename = os.path.basename(pathn)[: namelen]
                    if (exten.lower() == '.mbtiles'
                        and mbtilefilename == stripped_name):
                        tilesets.append(os.path.basename(filen))
                aois.append([basename, tilesets])    
    return render_template('mbtiles.html', title='MBTiles for download', aois = aois)

@app.route('/download_file/<path>')
def download_file(path):
    basename = os.path.basename(path)
    dirname = os.path.dirname(os.path.abspath(path))
    return send_file(os.path.join(dirname, 'files', basename), as_attachment = True)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        userdata = request.form
        if userdata['email'] == 'ivangayton@gmail.com':
            print('Login successful')
            session['logged_in'] = True
        else:
            session['logged_in'] = False
            print('Login failed for user {}'.format(userdata['email']))
        return render_template('profile.html', profile_info = userdata)
    else:
        return render_template('login.html')

@app.route('/profile')
def profile():
    print(session)
    if session.get('logged_in'):
        return render_template('profile.html', profile_info = {'email': session.get('email')})
    else:
        flash('You are not logged in. Please log in or sign up.')
        return render_template('login.html')

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        userdata = request.form
        session['logged_in'] = True
        session['email'] = userdata['email']
        return render_template('profile.html', profile_info = userdata)
    else:
        return render_template('signup.html')
    
