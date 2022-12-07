source venv/bin/activate
pip install -r requirements.txt
zip -r lambda-package.zip venv/lib/python3.10/site-packages/
zip -g lambda-package.zip data_scraper.py