import boto3
from load_dotenv import load_dotenv
from botocore.exceptions import ClientError
import os
load_dotenv()


s3_client = boto3.client('s3',
                         region_name='ca-central-1',
                         aws_access_key_id=os.environ['AWS_ACCESS_KEY_ID'],
                         aws_secret_access_key=os.environ['AWS_SECRET_ACCESS_KEY']
)

list_buckets= s3_client.list_buckets(
    MaxBuckets=10,
    Prefix='ramesh'
)
# for bucket in list_buckets['Buckets']:
#     print(f'Bucket_name {bucket["Name"]}, Creation date: {bucket["CreationDate"]}')
#     print("----------")


## to access a partiuclar bucket 
bucket_name = 'ramesh-ka-bucket'  # exact bucket name

# response = s3_client.list_objects_v2(
#     Bucket=bucket_name,
#     # Prefix='some/folder/path/'   # optional: filter to objects under this "folder"
# )

# if 'Contents' in response:
#     for obj in response['Contents']:
#         print(f'Key: {obj["Key"]}, Size: {obj["Size"]} bytes, Last Modified: {obj["LastModified"]}')
#         print("----------")
# else:
#     print("Bucket is empty or does not exist.")


## upload a file to bucket

local_file_path = 'D:/Codebase/aws-notes/Redshift/lambda_service/lambda_function.py'
s3_key = 'raw/lambda_function.py'  # destination path/name inside the bucket


try:
    s3_client.upload_file(local_file_path, bucket_name, s3_key)
    print(f"Uploaded {local_file_path} to s3://{bucket_name}/{s3_key}")
except ClientError as e:
    print(f'Failed Upload : {e}')

