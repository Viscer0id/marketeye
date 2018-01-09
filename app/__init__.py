from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from app.databaseconfig import MEConfig

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = MEConfig.connURL
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# json encoding
# from app.json_encoder import AlchemyEncoder
# app.json_encoder = AlchemyEncoder

from app import views, model
