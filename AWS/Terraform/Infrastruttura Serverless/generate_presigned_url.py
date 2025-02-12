import boto3
import sys

def generate_presigned_url(bucket_name, object_name, expiration=3600):
    """
    Genera un URL pre-firmato per caricare un file in S3.
    :param bucket_name: Nome del bucket S3
    :param object_name: Nome del file da caricare
    :param expiration: Scadenza dell'URL in secondi (default: 1 ora)
    :return: Pre-Signed URL
    """
    session = boto3.Session(profile_name="admin")  # Usa il profilo admin configurato
    s3 = session.client('s3')
    try:
        url = s3.generate_presigned_url('put_object',
                                        Params={'Bucket': bucket_name, 'Key': object_name},
                                        ExpiresIn=expiration)
        return url
    except Exception as e:
        print(f"Errore durante la generazione dell'URL: {e}")
        return None

if __name__ == "__main__":
    # Nome del bucket e del file come input da riga di comando
    if len(sys.argv) < 3:
        print("Uso: python generate_presigned_url.py <nome_bucket> <nome_file>")
        sys.exit(1)

    bucket_name = sys.argv[1]
    object_name = sys.argv[2]

    url = generate_presigned_url(bucket_name, object_name)
    if url:
        print("Pre-Signed URL:", url)
