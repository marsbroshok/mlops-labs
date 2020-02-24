# Copyright 2019 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#            http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import importlib
import joblib
import logging
import os
import subprocess
import sys
import time

import fire
import pickle
import numpy as np
import pandas as pd

from dask.distributed import Client, LocalCluster
from dask_ml.model_selection import GridSearchCV

from sklearn.linear_model import SGDClassifier
#from sklearn.model_selection import GridSearchCV
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler, OneHotEncoder
 
NUMERIC_FEATURE_INDEXES = slice(0, 10)
CATEGORICAL_FEATURE_INDEXES = slice(10, 12)
MODEL_FILE='model.joblib'

  
def train_evaluate(job_dir, training_dataset_path, search_space, scoring_measure):
  """Runs the training pipeline.""" 

  # Load and prepare training data  
  df_train = pd.read_csv(training_dataset_path)
  num_features_type_map = (
    {feature: 'float64' for feature in df_train.columns[NUMERIC_FEATURE_INDEXES]})
  df_train = df_train.astype(num_features_type_map)
  X_train = df_train.drop('Cover_Type', axis=1)
  y_train = df_train['Cover_Type']

  # Define the training pipeline
  preprocessor = ColumnTransformer(
    transformers=[
        ('num', StandardScaler(), NUMERIC_FEATURE_INDEXES),
        ('cat', OneHotEncoder(), CATEGORICAL_FEATURE_INDEXES) 
    ])

  pipeline = Pipeline([
    ('preprocessor', preprocessor),
    ('classifier', SGDClassifier())
  ])
  
  # Configure hyperparameter tuning
  grid = GridSearchCV(pipeline, cv=5,  
                      param_grid=search_space, 
                      scoring=scoring_measure)
  
  # Start training
  grid.fit(X_train, y_train)
    
  return grid
    
def run_dask_job(job_dir, training_dataset_path, search_space, scoring_measure, n_workers=None, threads_per_worker=None):
  """Runs a parallel training job."""
  
  # Configure parameter grid
  for classifier in search_space:
    module_name, class_name = classifier["classifier"].rsplit(".", 1)
    ClassifierClass = getattr(importlib.import_module(module_name), class_name)
    classifier["classifier"] = [ClassifierClass()]
    
  # Set up a local Dask cluster
  cluster = LocalCluster(n_workers=n_workers, processes=True, threads_per_worker=threads_per_worker)
  client = Client(cluster)
  logging.info("Cluster: {}".format(cluster))
    
  logging.info("Starting training ...")
  t0= time.time()
  result = train_evaluate(job_dir, training_dataset_path, search_space, scoring_measure)
  t1 = time.time()
  logging.info("Elapsed time: {}".format(t1-t0))
  logging.info("Best accuracy: {}".format(result.best_score_))
  logging.info("Best estimater: {}".format(result.best_estimator_))
 
  # Persist the pipeline
  if job_dir[0:2] == 'gs':
    joblib.dump(result.best_estimator_, MODEL_FILE)
    model_path = "{}/model/{}".format(job_dir, MODEL_FILE)
    subprocess.check_call(['gsutil', 'cp', MODEL_FILE, model_path], stderr=sys.stdout)
    
  else:
    model_path = os.path.join(job_dir, MODEL_FILE)
    joblib.dump(result.best_estimator_, model_path)
    
  logging.info("Saved model in: {}".format(model_path))
    
if __name__ == "__main__":
  logging.basicConfig(level=logging.INFO)
  fire.Fire(run_dask_job)