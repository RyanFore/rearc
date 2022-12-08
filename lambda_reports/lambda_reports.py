import json
import logging
from io import StringIO

import pandas as pd
import boto3


logger = logging.getLogger("reports")
s3 = boto3.client("s3")
bucket = 'ryanfore-rearc'


def lambda_handler(event, context):
    acs_data = s3.get_object(Bucket=bucket, Key='population_data.json')['Body'].read()
    pr_data = s3.get_object(Bucket=bucket, Key='pr.data.0.Current')['Body'].read()

    acs_dict = json.loads(acs_data)['data']
    acs_df = pd.DataFrame.from_records(acs_dict)
    acs_df['Year'] = pd.to_numeric(acs_df['Year'])
    acs_df.columns = acs_df.columns.map(lambda x: x.replace(' ', '_').lower())
    population = acs_df[acs_df['year'] <= 2018]['population'] # Assumes the data will continue to start at 2013
    logger.info('Population mean is: ' + f'{population.mean():,}')
    logger.info('Population standard deviation is: ' + f'{population.std():,}')
    print('Population mean is: ' + f'{population.mean():,}')
    print('Population standard deviation is: ' + f'{population.std():,}')

    s = str(pr_data, 'utf-8')
    pr_df = pd.read_csv(StringIO(s), sep='\t')
    pr_df.columns = pr_df.columns.str.replace(' ', '')
    pr_df['period'] = pr_df['period'].str.strip()
    pr_df['series_id'] = pr_df['series_id'].str.strip()
    id_year = pr_df.groupby(by=['series_id', 'year']).sum('value').reset_index()
    best_years = id_year.loc[id_year.groupby('series_id')['value'].idxmax()]
    logger.info(best_years.head(5).to_string().replace('\n', '\n\t'))
    print(best_years.head(5).to_string().replace('\n', '\n\t'))

    selected_quarter_df = pr_df[(pr_df['series_id'] == 'PRS30006032') & (pr_df['period'] == 'Q01')]
    cols_to_select = ['series_id', 'year', 'period', 'value', 'population']
    joined = selected_quarter_df.merge(acs_df, on='year')
    pop_by_year = joined[cols_to_select]
    logger.info(pop_by_year.to_string().replace('\n', '\n\t'))
    print(pop_by_year.to_string().replace('\n', '\n\t'))

