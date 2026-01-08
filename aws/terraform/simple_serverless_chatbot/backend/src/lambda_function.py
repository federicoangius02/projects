import json
import boto3  # type: ignore
import os
import logging
from datetime import datetime, timezone
import uuid

# Setup logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    """
    Main Lambda handler per il chatbot
    """
    try:
        # Log dell'evento ricevuto
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Parse del body se viene da API Gateway
        if 'body' in event:
            if isinstance(event['body'], str):
                body = json.loads(event['body'])
            else:
                body = event['body']
        else:
            body = event
            
        # Estrai il messaggio dell'utente
        user_message = body.get('message', '').strip()
        user_id = body.get('userId', 'anonymous')
        
        if not user_message:
            return create_response(400, {
                'error': 'Message is required',
                'message': 'Please provide a message to chat with the bot'
            })
        
        # Genera ID conversazione
        conversation_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Per ora, risposta mock (sostituiremo con OpenAI)
        ai_response = get_ai_response(user_message)
        
        # Salva la conversazione in DynamoDB
        save_conversation(conversation_id, user_id, user_message, ai_response, timestamp)
        
        # Ritorna la risposta
        return create_response(200, {
            'response': ai_response,
            'conversationId': conversation_id,
            'timestamp': timestamp
        })
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return create_response(500, {
            'error': 'Internal server error',
            'message': 'Sorry, something went wrong. Please try again.'
        })

def get_ai_response(user_message):
    """
    Ottiene risposta AI. Per ora è mock, poi integreremo OpenAI
    """
    # Mock response per testing
    mock_responses = {
        'ciao': 'Ciao! Come posso aiutarti oggi?',
        'hello': 'Hello! How can I help you?',
        'come stai': 'Sono un bot, ma funziono bene! Tu come stai?',
        'chi sei': 'Sono un chatbot AI creato per aiutarti. Sono ancora in fase di sviluppo!',
    }
    
    # Cerca risposta mock
    user_lower = user_message.lower()
    for key, response in mock_responses.items():
        if key in user_lower:
            return response
    
    # Risposta di default
    return f"Hai scritto: '{user_message}'. Al momento sono in modalità test, ma presto potrò rispondere con l'AI!"

def save_conversation(conversation_id, user_id, user_message, ai_response, timestamp):
    """
    Salva la conversazione in DynamoDB
    """
    try:
        table_name = os.environ.get('DYNAMODB_TABLE')
        if not table_name:
            logger.warning("DynamoDB table name not configured")
            return
            
        table = dynamodb.Table(table_name)
        
        item = {
            'conversationId': conversation_id,
            'userId': user_id,
            'timestamp': timestamp,
            'userMessage': user_message,
            'aiResponse': ai_response,
            'messageLength': len(user_message),
            'responseLength': len(ai_response)
        }
        
        table.put_item(Item=item)
        logger.info(f"Conversation saved: {conversation_id}")
        
    except Exception as e:
        logger.error(f"Error saving conversation: {str(e)}")
        # Non blocchiamo l'esecuzione se il salvataggio fallisce

def create_response(status_code, body):
    """
    Crea una risposta HTTP formattata per API Gateway
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',  # CORS per il frontend
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps(body, ensure_ascii=False)
    }