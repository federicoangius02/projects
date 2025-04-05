import boto3
import os

REGION = 'eu-south-1'
BUCKET_NAME = 'angius-my-first-boto3-bucket'
FILE_NAME = 'test.txt'

s3 = boto3.client('s3', region_name=REGION)

response = s3.create_bucket(
    Bucket=BUCKET_NAME,
    CreateBucketConfiguration={'LocationConstraint': REGION}
)

print(f"Bucket {BUCKET_NAME} created: ", response)

with open(FILE_NAME, 'w') as f:
    f.write('Hello, world from Boto3!')

s3.upload_file(Filename=FILE_NAME, Bucket=BUCKET_NAME, Key=FILE_NAME)
print(f"File {FILE_NAME} uploaded to bucket {BUCKET_NAME}.")

s3.download_file(BUCKET_NAME, FILE_NAME, 'scaricato.txt')

s3.delete_object(Bucket=BUCKET_NAME, Key=FILE_NAME)
print(f"File {FILE_NAME} deleted from bucket {BUCKET_NAME}.")

#s3.delete_bucket(Bucket=BUCKET_NAME)
print(f"Bucket {BUCKET_NAME} deleted.")

os.remove(FILE_NAME)
os.remove('scaricato.txt')
print(f"Files {FILE_NAME} and scaricato.txt deleted.")