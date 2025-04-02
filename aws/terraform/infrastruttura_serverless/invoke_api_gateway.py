import boto3
import requests
from requests_aws4auth import AWS4Auth

# Carica le credenziali dal profilo AWS admin
session = boto3.Session(profile_name="admin")
credentials = session.get_credentials().get_frozen_credentials()

# Recupera le credenziali e configura l'autenticazione
aws_access_key = credentials.access_key
aws_secret_key = credentials.secret_key
region = session.region_name
service = "execute-api"

auth = AWS4Auth(aws_access_key, aws_secret_key, region, service)

# URL dell'API Gateway
url = "https://hu3h1ikap3.execute-api.us-east-1.amazonaws.com/prod/crud"

# Corpo della richiesta DELETE
body = {
    "id": "mars.jpg"
}

# Invia la richiesta DELETE firmata
response = requests.delete(url, json=body, auth=auth)

# Stampa la risposta
print("Status Code:", response.status_code)
print("Response Body:", response.text)
