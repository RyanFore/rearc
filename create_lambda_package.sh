#source venv/bin/activate
#pip install -r requirements.txt
#zip -r lambda_package.zip venv/lib/python3.10/site-packages/
#zip -g lambda_package.zip lambda_scraper.py

id=$(aws sts get-caller-identity --query "Account" --output text)
region=$(eval "aws configure get region")
echo $id
echo $region
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${id}.dkr.ecr.${region}.amazonaws.com
docker build -t scraper_image .
docker tag scraper_image ${id}.dkr.ecr.${region}.amazonaws.com/rearc
docker push ${id}.dkr.ecr.${region}.amazonaws.com/rearc
