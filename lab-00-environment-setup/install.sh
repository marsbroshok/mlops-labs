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

if [[ $# < 2 ]]; then
  echo 'USAGE:  ./install.sh PROJECT_ID NAME_PREFIX [REGION=us-central1] [ZONE=us-central1-a] [NAMESPACE=kubeflow]'
  exit 1
fi

PROJECT_ID=${1}
NAME_PREFIX=${2}
REGION=${3:-us-central1} 
ZONE=${4:-us-central1-a}
NAMESPACE=${5:-kubeflow}

INSTANCE_NAME=${NAME_PREFIX}-notebook
IMAGE_FAMILY="common-container"
IMAGE_PROJECT="deeplearning-platform-release"
INSTANCE_TYPE="n1-standard-4"
CONTAINER_IMAGE="gcr.io/mlops-workshop/mlops-dev:TF115-TFX015-KFP136"
METADATA="proxy-mode=service_account,container=$CONTAINER_IMAGE"

SQL_USERNAME=root

# Enable services
echo INFO: Enabling required services

gcloud config set project $PROJECT_ID

#gcloud services enable \
#cloudbuild.googleapis.com \
#container.googleapis.com \
#cloudresourcemanager.googleapis.com \
#iam.googleapis.com \
#containerregistry.googleapis.com \
#containeranalysis.googleapis.com \
#ml.googleapis.com 

if [ $? -eq 0 ]; then
    echo INFO: Required services enabled
else
    exit $?
fi

# Provision an AI Platform Notebook instance

INSTANCE_NAME=${NAME_PREFIX}-notebook

if [ $(gcloud compute instances list --filter="name=$INSTANCE_NAME" --zones $ZONE --format="value(name)") ]; then
    echo INFO: Instance $INSTANCE_NAME exists in $ZONE. Skipping provisioning
else
    echo INFO: Starting provisioning of $INSTANCE_NAME in $ZONE

    gcloud compute instances create $INSTANCE_NAME \
    --zone=$ZONE \
    --image-family=$IMAGE_FAMILY \
    --machine-type=$INSTANCE_TYPE \
    --image-project=$IMAGE_PROJECT \
    --maintenance-policy=TERMINATE \
    --boot-disk-device-name=$INSTANCE_NAME-disk \
    --boot-disk-size=100GB \
    --boot-disk-type=pd-ssd \
    --scopes=cloud-platform,userinfo-email \
    --metadata=$METADATA
fi

if [ $? -ne 0 ]; then
    exit $?
fi

### Configure KPF infrastructure
pushd terraform

# Start terraform build
echo INFO: Starting Terraform 

terraform init
terraform apply  \
-auto-approve \
-var "project_id=$PROJECT_ID" \
-var "region=$REGION" \
-var "zone=$ZONE" \
-var "name_prefix=$NAME_PREFIX" 

if [ $? -eq 0 ]; then
    echo INFO: Terraform config completed successfully
else
    exit $?
fi

# Deploy KFP
# Retrieve resource names
CLUSTER_NAME=$(terraform output cluster_name)
KFP_SA_EMAIL=$(terraform output kfp_sa_email)
SQL_INSTANCE_NAME=$(terraform output sql_name)
SQL_CONNECTION_NAME=$(terraform output sql_connection_name)
BUCKET_NAME=$(terraform output artifact_store_bucket)
ZONE=$(terraform output cluster_zone)

popd

pushd kustomize

# Create a namespace for KFP components
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID
kubectl create namespace $NAMESPACE
kustomize edit set namespace $NAMESPACE

# Configure user-gpc-sa with a private key of the KFP service account
gcloud iam service-accounts keys create application_default_credentials.json --iam-account=$KFP_SA_EMAIL --project $PROJECT_ID
kubectl create secret -n $NAMESPACE generic user-gcp-sa --from-file=application_default_credentials.json --from-file=user-gcp-sa.json=application_default_credentials.json
rm application_default_credentials.json

# Create a Cloud SQL database user and store its credentials in mysql-credential secret
gcloud sql users create $SQL_USERNAME --instance=$SQL_INSTANCE_NAME --password=$SQL_PASSWORD --project $PROJECT_ID
kubectl create secret -n $NAMESPACE generic mysql-credential --from-literal=username=$SQL_USERNAME --from-literal=password=$SQL_PASSWORD

# Generate an environment file with connection settings to Cloud SQL and artifact store
cat > gcp-configs.env << EOF
sql_connection_name=$SQL_CONNECTION_NAME
bucket_name=$BUCKET_NAME
EOF

# Deploy KFP to the cluster
kustomize build . | kubectl apply -f -

popd

echo INFO: KFP UI can be accessed at the below URI:
echo "https://"$(kubectl describe configmap inverse-proxy-config -n $NAMESPACE | grep "googleusercontent.com")