from flask import Flask
from config import Config

app = Flask(__name__)
app.config.from_object(Config)

from app import routes
import rq

print('Hi, I am the init script')

def create_app(config_class=Config):
    print('Hello, I am the create_app function')
    app.redis = Redis.from_url(app.config['REDIS_URL'])
    app.task_queue = rq.Queue('tilehuria-tasks', connection=app.redis)
