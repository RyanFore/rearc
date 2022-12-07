source venv/bin/activate
pip install -r requirements.txt
zip -r lambda_package.zip venv/lib/python3.10/site-packages/
zip -g lambda_package.zip lambda_scraper.py