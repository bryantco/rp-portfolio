import polars as pl
import yaml
import os
import sys
import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--df_es')
    parser.add_argument('--df_hs')
    parser.add_argument('--config')
    parser.add_argument('--df_hs_for_rf')
    args = parser.parse_args()

    config = yaml.safe_load(open(args.config, 'r'))

    # Prep the eighth grade dataset for merge ----
    df_es = pl.read_parquet(args.df_es)

    features_eighth_grade = config['features_eighth_grade']

    df_eighth_graders = df_es.filter(
        pl.col('annual_grade_num') == 8
    ).select(
        ['sid'] + features_eighth_grade
    ).rename(
        {col: f"{col}_8thgrd" for col in features_eighth_grade}
    ).unique('sid')

    # Merge eighth grade data into high school dataset ----
    df_hs = pl.read_parquet(args.df_hs)
    df_hs = df_hs.join(
        df_eighth_graders,
        on='sid',
        how='left'
    )

    df_hs.write_parquet(args.df_hs_for_rf)
    
    
