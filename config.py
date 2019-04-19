import os

class Config(object):
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'plumpynut'
    SQLALCHEMY_DATABASE_URI = 'sqlite:///db.sqlite'

    # Supress deprecation warning
    SQLALCHEMY_TRACK_MODIFICATIONS = False 

