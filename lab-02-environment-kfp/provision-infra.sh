#!/bin/bash
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

# Provision infrastructure to host KFP components

# Set up a global error handler
err_handler() {
    echo "Error on line: $1"
    echo "Caused by: $2"
    echo "That returned exit status: $3"
    echo "Aborting..."
    exit $3
}

trap 'err_handler "$LINENO" "$BASH_COMMAND" "$?"' ERR

# Check command line parameters
if [[ $# < 1 ]]; then
  echo "Error: Arguments missing. PROJECT_ID [NAME_PREFIX=PROJECT_ID] [REGION=us-central1] [ZONE=us-central1-a]"
  exit 1
fi

PROJECT_ID=${1}
NAME_PREFIX=${2:-$PROJECT_ID}
REGION=${3:-us-central1} 
ZONE=${4:-us-central1-a}

# Set project
echo INFO: Setting the project to: $PROJECT_ID
gcloud config set project $PROJECT_ID

# Enable services
echo INFO: Enabling required services

gcloud services enable \
cloudbuild.googleapis.com \
container.googleapis.com \
cloudresourcemanager.googleapis.com \
iam.googleapis.com \
containerregistry.googleapis.com \
containeranalysis.googleapis.com \
ml.googleapis.com \
sqladmin.googleapis.com \
dataflow.googleapis.com 
#automl.googleapis.com

### Configure KPF infrastructure
pushd terraform

# Start terraform build
echo INFO: Provisioning KFP infrastructure 

terraform init
terraform apply  \
-var "project_id=$PROJECT_ID" \
-var "region=$REGION" \
-var "zone=$ZONE" \
-var "name_prefix=$NAME_PREFIX"

popd
echo INFO: KFP infrastructure provisioned successfully





