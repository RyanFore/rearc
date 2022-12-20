id=$(aws sts get-caller-identity --query "Account" --output text)
region=$(eval "aws configure get region")
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${id}.dkr.ecr.${region}.amazonaws.com

docker build -t scraper_image . # --no-cache
docker tag scraper_image ${id}.dkr.ecr.${region}.amazonaws.com/rearc_scraper
docker push ${id}.dkr.ecr.${region}.amazonaws.com/rearc_scraper

aws lambda update-function-code --function-name rearc_terraform_scraper --image-uri ${id}.dkr.ecr.${region}.amazonaws.com/rearc_scraper:latest
# aws lambda update-function-code --function-name rearc_terraform_scraper --image-uri 385871096247.dkr.ecr.us-east-1.amazonaws.com/rearc_scraper:latest


# docker exec -ti $(docker ps -q --filter "ancestor=scraper_image") /bin/bash
