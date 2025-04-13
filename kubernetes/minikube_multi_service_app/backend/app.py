from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)

# Configurazione del database
DB_USER = os.getenv("POSTGRES_USER", "postgres")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD", "mysecretpassword")
DB_HOST = os.getenv("POSTGRES_SERVICE_SERVICE_HOST", "localhost")
DB_PORT = os.getenv("POSTGRES_SERVICE_SERVICE_PORT", "5432")
DB_NAME = os.getenv("POSTGRES_DB", "postgres")

app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Definizione modello base
class Utente(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(50), nullable=False)

# Endpoint base
@app.route("/api")
def hello():
    return "Backend con DB funziona!"

# Endpoint per ottenere utenti
@app.route("/api/utenti")
def get_utenti():
    utenti = Utente.query.all()
    return jsonify([{"id": u.id, "nome": u.nome} for u in utenti])

if __name__ == "__main__":
    with app.app_context():
        db.create_all()  # Crea le tabelle se non esistono
    app.run(host="0.0.0.0", port=5000)
