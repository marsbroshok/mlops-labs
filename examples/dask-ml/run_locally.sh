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
'classifier__alpha':[0.0001,0.0002,0.0004,0.0008],\
'classifier__max_iter':[250,500]}\
]"
N_WORKERS=4
THREADS_PER_WORKER=2
JOB_DIR=/tmp

python hypertune.py $JOB_DIR $TRAINING_DATASET $SEARCH_SPACE $SCORING_MEASURE $N_WORKERS $THREADS_PER_WORKER
echo "Done"




#{'classifier':'sklearn.linear_model.SGDClassifier',\
#'classifier__alpha':[0.0001,0.0002,0.0004,0.0008,0.001],\
#'classifier__max_iter':[250,500,1000]},\
#{'classifier':'sklearn.neighbors.KNeighborsClassifier',\
#'classifier__n_neighbors':[3,5,7,10],\
#'classifier__p':[1,2]}\
#]"