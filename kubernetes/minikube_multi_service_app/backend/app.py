from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
import os
import logging

app = Flask(__name__)
CORS(app)  # Abilita CORS per tutte le rotte

# Configurazione base del logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configurazione del database
app.config['SQLALCHEMY_DATABASE_URI'] = (
    f"postgresql://"
    f"{os.getenv('POSTGRES_USER', 'postgres')}:"
    f"{os.getenv('POSTGRES_PASSWORD', 'mysecretpassword')}@"
    f"{os.getenv('POSTGRES_SERVICE_SERVICE_HOST', 'postgres-service')}:"
    f"{os.getenv('POSTGRES_SERVICE_SERVICE_PORT', '5432')}/"
    f"{os.getenv('POSTGRES_DB', 'postgres')}"
)
db = SQLAlchemy(app)

# Modello semplice
class Utente(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nome_completo = db.Column(db.String(50))

# Crea le tabelle al primo avvio
with app.app_context():
    db.create_all()
    logger.info("Database inizializzato")

# Endpoint base - risponde a /api
@app.route("/api", methods=["GET"])
def api_root():
    logger.info("Richiesta API ricevuta")
    return jsonify({"message": "Hello from the backend!"})

# Endpoint per verificare il database
@app.route("/api/db-check", methods=["GET"])
def db_check():
    try:
        Utente.query.first()
        logger.info("Database check successful")
        return jsonify({"status": "Database connesso correttamente"})
    except Exception as e:
        logger.error(f"Errore database: {str(e)}")
        return jsonify({"error": f"Errore database: {str(e)}"}), 500

# Endpoint per gestire utenti
@app.route("/api/utenti", methods=["GET", "POST"])
def utenti():
    if request.method == "POST":
        nome_completo = request.json.get('nome_completo')
        if not nome_completo:
            return jsonify({"error": "Nome completo mancante"}), 400

        nuovo_utente = Utente(nome_completo=nome_completo)
        db.session.add(nuovo_utente)
        db.session.commit()
        logger.info(f"Creato utente: {nome_completo}")
        return jsonify({"message": f"Utente {nome_completo} creato"}), 201

    # GET
    utenti = Utente.query.all()
    logger.info(f"Recuperati {len(utenti)} utenti")
    return jsonify([{"id": u.id, "nome_completo": u.nome_completo} for u in utenti])

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)