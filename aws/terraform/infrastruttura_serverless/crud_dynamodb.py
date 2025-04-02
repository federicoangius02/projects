import boto3
import os
import json
from datetime import datetime, timezone

# Configura il client DynamoDB
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DYNAMODB_TABLE']  # Legge il nome della tabella dalla variabile d'ambiente
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    method = event['httpMethod']
    if method == 'GET':
        # Legge i dati dalla tabella
        response = table.scan()
        return {
            'statusCode': 200,
            'body': json.dumps(response['Items'])
        }
    elif method == 'POST':
        # Aggiunge un nuovo elemento
        body = json.loads(event['body'])
        table.put_item(Item=body)
        return {
            'statusCode': 200,
            'body': json.dumps('Item added!')
        }
    elif method == 'DELETE':
        # Elimina un elemento
        body = json.loads(event['body'])
        key = body['id']
        table.delete_item(Key={'id': key})
        return {
            'statusCode': 200,
            'body': json.dumps('Item deleted!')
        }
