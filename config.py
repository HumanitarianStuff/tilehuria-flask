import os

class Config(object):
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'plumpynut'
    REDIS_URL = os.environ.get('REDIS_URL') or 'redis://'
