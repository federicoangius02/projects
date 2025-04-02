import boto3
import os
import json
from datetime import datetime, timezone

# Configura il client DynamoDB
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DYNAMODB_TABLE']  # Legge il nome della tabella dalla variabile d'ambiente
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        file_name = record['s3']['object']['key']
        file_size = record['s3']['object']['size']

        # Inserisce i metadati nella tabella DynamoDB
        table.put_item(
            Item={
                'id': file_name,
                'bucket_name': bucket_name,
                'timestamp': datetime.now(timezone.utc).isoformat(),  # Timestamp con timezone
                'file_size': f"{file_size} bytes"
            }
        )
    return {
        'statusCode': 200,
        'body': json.dumps('Metadata saved to DynamoDB')
    }
