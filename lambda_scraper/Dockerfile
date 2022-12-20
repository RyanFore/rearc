FROM public.ecr.aws/lambda/python:3.9
RUN yum install -y vim
RUN yum install -y wget
RUN yum install -y unzip
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install

COPY lambda_scraper.py requirements.txt ./
RUN python3.9 -m pip install -r requirements.txt

COPY lambda_scraper.py ${LAMBDA_TASK_ROOT}

# Overwrite the command by providing a different command directly in the template.
CMD ["lambda_scraper.lambda_handler"]