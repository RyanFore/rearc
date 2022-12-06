import subprocess
import requests
import json
import boto3

api_url = "https://datausa.io/api/data?drilldowns=Nation&measures=Population"
bls_url = "https://download.bls.gov/pub/time.series/pr/"
bucket_name = "ryanfore-rearc"
acs_key_name = 'acs_data.json'

# subprocess.run(["wget", "-r", "-np", "--mirror", "-nd", {bls_url} "-P", "./data"])
# subprocess.run(["aws", "s3", "sync", "./bls_data", f"s3://{bucket_name}/data",
#                 "--delete", "--exclude", "*.html", ])

subprocess.run(f"wget -r -np --mirror -nd {bls_url} -P ./data".split(' '))
subprocess.run(f"aws s3 sync ./data s3://{bucket_name} --delete --exclude *.html --exclude {acs_key_name}".split(' '))

response = requests.get(api_url).json()
s3 = boto3.client('s3')
s3.put_object(Body=json.dumps(response),
              Bucket=bucket_name,
              Key='acs_data.json')
