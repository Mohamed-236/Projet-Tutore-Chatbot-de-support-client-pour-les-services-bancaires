import os

class Config:
      # Chaîne de connexion PostgreSQL
    SQLALCHEMY_DATABASE_URI = 'postgresql://postgres:admin123@localhost:5433/chatbot_bancaire_db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = os.urandom(24)