from . import db

class User(dm.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(199), unique=True)
    password = db.Column(db.String(100))
    name = db.Column(db.String(100))
    
