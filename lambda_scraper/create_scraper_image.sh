id=$(aws sts get-caller-identity --query "Account" --output text)
region=$(eval "aws configure get region")
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${id}.dkr.ecr.${region}.amazonaws.com

docker build -t scraper_image .
docker tag scraper_image ${id}.dkr.ecr.${region}.amazonaws.com/rearc_scraper
docker push ${id}.dkr.ecr.${region}.amazonaws.com/rearc_scraper

