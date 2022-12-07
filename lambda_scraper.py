import os
import subprocess
import json

import requests
import boto3
from bs4 import BeautifulSoup

population_url = "https://datausa.io/api/data?drilldowns=Nation&measures=Population"
bls_url = "https://download.bls.gov/pub/time.series/pr"

bucket_name = "ryanfore-rearc"
population_key_name = 'population_data.json'

local_folder = 'data'
if not os.path.exists(local_folder):
    os.makedirs(local_folder)

# Part 1
response = requests.get(bls_url)
soup = BeautifulSoup(response.text, features="html.parser")

for node in soup.find_all('a'):
    file_name = node.get('href').lstrip('/')
    if file_name.endswith('/'):
        pass
    else:
        base_name = os.path.basename(file_name)
        full_url = os.path.join(bls_url, file_name)
        write_path = os.path.join(local_folder, base_name) + '/'

        file_data = requests.get(full_url).content
        with open(os.path.join(local_folder, base_name), 'wb') as file:
            file.write(file_data)

subprocess.run(f"aws s3 sync ./{local_folder} s3://{bucket_name} --delete --exclude {population_key_name}".split(' '))

# Part 2
response = requests.get(population_url).json()
s3 = boto3.client('s3')
s3.put_object(Body=json.dumps(response),
              Bucket=bucket_name,
              Key=population_key_name)
