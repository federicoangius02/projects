from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)

# Configurazione base del database
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
    nome = db.Column(db.String(50))

# Crea le tabelle al primo avvio
with app.app_context():
    db.create_all()

# Endpoint base
@app.route("/api")
def hello():
    return "Backend funziona!"

# Endpoint per verificare il database
@app.route("/api/db-check")
def db_check():
    try:
        Utente.query.first()  # Prova una semplice query
        return "Database connesso correttamente"
    except Exception as e:
        return f"Errore database: {str(e)}", 500

# Endpoint per gestire utenti (solo GET e POST)
@app.route("/api/utenti", methods=["GET", "POST"])
def utenti():
    if request.method == "POST":
        nome = request.json.get('nome')
        if not nome:
            return "Nome mancante", 400
            
        nuovo_utente = Utente(nome=nome)
        db.session.add(nuovo_utente)
        db.session.commit()
        return f"Utente {nome} creato", 201
    
    # GET
    utenti = Utente.query.all()
    return jsonify([{"id": u.id, "nome": u.nome} for u in utenti])

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)