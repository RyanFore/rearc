import subprocess
import json

import requests
import boto3

api_url = "https://datausa.io/api/data?drilldowns=Nation&measures=Population"
bls_url = "https://download.bls.gov/pub/time.series/pr/"
bucket_name = "ryanfore-rearc"
population_key_name = 'population_data.json'
local_folder = 'data'

subprocess.run(f"wget -r -np -nd  --mirror {bls_url} -P ./{local_folder}".split(' '))
subprocess.run(f"aws s3 sync ./{local_folder} s3://{bucket_name} --delete "
               f"--exclude *.html --exclude {population_key_name}"  # Don't want to delete the pop. data
               .split(' '))

response = requests.get(api_url).json()
s3 = boto3.client('s3')
s3.put_object(Body=json.dumps(response),
              Bucket=bucket_name,
              Key=population_key_name)
