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


TRAINING_DATASET=gs://workshop-datasets/covertype/evaluation/dataset.csv
SCORING_MEASURE=accuracy
SEARCH_SPACE="[\
{'classifier':'sklearn.linear_model.SGDClassifier',\
'classifier__alpha':[0.0001,0.0002,0.0004,0.0008,0.001,0.002],\
'classifier__max_iter':[250,500,750,1000]},\
{'classifier':'sklearn.neighbors.KNeighborsClassifier',\
'classifier__n_neighbors':[3,5,7,10,12,14],\
'classifier__p':[1,2]}\
]"


IMAGE_URI=gcr.io/jk-dask-test1/dask_ml_trainer
JOB_BUCKET=gs://jk-dask-test1-bucket

JOB_NAME=JOB_$(date +"%Y%m%d%s")
JOB_DIR=${JOB_BUCKET}/jobs/${JOB_NAME}
REGION=us-central1

CPU_NUMBER=64
MASTER_MACHINE_TYPE=n1-highmem-${CPU_NUMBER}
THREADS_PER_WORKER=4
N_WORKERS=16


gcloud ai-platform jobs submit training $JOB_NAME \
--region=$REGION \
--job-dir=$JOB_DIR \
--master-image-uri=$IMAGE_URI \
--scale-tier=CUSTOM \
--master-machine-type=$MASTER_MACHINE_TYPE \
-- \
--training_dataset_path=$TRAINING_DATASET \
--search_space=$SEARCH_SPACE \
--scoring_measure=$SCORING_MEASURE 
#--n_workers=$N_WORKERS \
#--threads_per_worker=$THREADS_PER_WORKER





