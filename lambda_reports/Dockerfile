FROM public.ecr.aws/lambda/python:3.8
RUN yum install wget

COPY lambda_scraper.py requirements.txt ./

RUN python3.8 -m pip install -r requirements.txt

# Overwrite the command by providing a different command directly in the template.
CMD ["lambda_scraper.lambda_handler"]