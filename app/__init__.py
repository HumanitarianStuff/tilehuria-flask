from flask import Flask
from config import Config

# Login stuff
from flask_sqlalchemy import SQLAlchemy
db = SQLAlchemy()

app = Flask(__name__)
app.config.from_object(Config)

db.init_app(app)

from app import routes
