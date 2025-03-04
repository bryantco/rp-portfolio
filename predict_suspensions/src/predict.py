import polars as pl
import numpy as np
import yaml
from sklearn.ensemble import RandomForestRegressor
from sklearn.impute import SimpleImputer
import argparse

np.random.seed(12345)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--df_hs_for_rf')
    parser.add_argument('--config')
    parser.add_argument('--df_hs_predicted_oss')
    args = parser.parse_args()

    df_hs = pl.read_parquet(args.df_hs_for_rf)

    config = yaml.safe_load(open(args.config,'r'))
    features_for_rf = config['features_for_rf']

    # Use students from 2013 as training data; 2013 was prior to the rollout
    # of the policy, so the outcome (out-of-school suspensions) won't be 
    # contaminated by any treatment effect
    df_train = df_hs.filter(
        (pl.col('file_sy') == 2013) & (pl.col('oss_days').is_not_null())
    )

    # Train the random forest using pre-specified parameters
    # Previous validation work (not shown in this task) empirically showed that
    # test accuracy from the default settings in sklearn.ensemble.RandomForestRegressor
    # was worse or only marginally improved; so just use the default settings.
    X_train = df_train.select(features_for_rf).to_numpy()
    y_train = df_train.select(pl.col('oss_days')).to_numpy().ravel()

    # Impute the mean in the training dataset for missing values
    imp_mean = SimpleImputer(strategy='mean').fit(X_train)
    X_train = imp_mean.transform(X_train)

    rf_model_oss = RandomForestRegressor().fit(
        X=X_train,
        y=y_train
    )

    # Use the model to predict out-of-school suspensions on the entire
    # dataset
    X_complete = imp_mean.transform(
        df_hs.select(features_for_rf).to_numpy()
    )

    oss_days_predicted = rf_model_oss.predict(X_complete)

    df_hs = df_hs.with_columns(
        pl.Series('oss_days_predicted', oss_days_predicted)
    )

    # Save with predicted values
    df_hs.write_parquet(args.df_hs_predicted_oss)
