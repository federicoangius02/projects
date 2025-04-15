# Immagine base ufficiale Python (versione slim per ridurre le dimensioni)
FROM python:3.9-slim

# Installa curl per eventuali test o download di file
RUN apt-get update && apt-get install -y --no-install-recommends curl

WORKDIR /app

# Copia solo i file necessari per installare le dipendenze
COPY requirements.txt .

# Installazione dipendenze (con pulizia cache per ridurre l'immagine)
RUN pip install --no-cache-dir -r requirements.txt

# Copia il resto dell'applicazione
COPY . .

# Variabili d'ambiente consigliate
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Esposione della porta (solo a scopo documentativo, Flask usa 5000 di default)
EXPOSE 5000

# Comando di avvio dell'applicazione
CMD ["python", "app.py"]