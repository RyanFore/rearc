FROM public.ecr.aws/lambda/python:3.9

COPY lambda_reports.py requirements.txt ./

RUN python3.9 -m pip install -r requirements.txt

# Overwrite the command by providing a different command directly in the template.
CMD ["lambda_reports.lambda_handler"]