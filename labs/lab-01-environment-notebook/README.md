# Setting up an MLOps environment on GCP - Part 1 - Creating an AI Platform Notebooks instance

The labs in this repo are designed to run in the reference MLOps environment. The environment is configured to support effective development and operationalization of production grade ML workflows.

![Reference topolgy](/images/lab_300.png)

The core services in the environment are:
- ML experimentation and development - AI Platform Notebooks 
- Scalable, serverless model training - AI Platform Training  
- Scalable, serverless model serving - AI Platform Prediction 
- Distributed data processing - Dataflow  
- Analytics data warehouse - BigQuery 
- Artifact store - Google Cloud Storage 
- Machine learning pipelines - TensorFlow Extended (TFX) and Kubeflow Pipelines (KFP)
- Machine learning metadata  management - ML Metadata on Cloud SQL
- CI/CD tooling - Cloud Build
    
In the reference lab environment, all services are provisioned in the same [Google Cloud Project](https://cloud.google.com/storage/docs/projects). 

The provisioning of the environment has been fully automated as described in `lab-00-environment-setup`.  

As an alternative to a fully automated setup, `lab-01-environment-notebook` and `lab-02-environment-kfp` describe the semi-manual process to individually provision components of the environment.

This lab - `lab-01-environment-notebook` - walks you through the steps required to provision  an AI Platfom Notebooks instance configured based on a custom container image optimized for TFX/KFP development.

The accompanying lab - `lab-02-environment-kfp` - describe the steps to provision Cloud SQL, GKE and GCS and deploying Kubeflow Pipelines

## Enabling the required cloud services

In addition to the [services enabled by default](https://cloud.google.com/service-usage/docs/enabled-service), the following additional services must be enabled in the project hosting an MLOps environment:

1. Compute Engine
1. Container Registry
1. AI Platform Training and Prediction
1. IAM
1. Dataflow
1. Kubernetes Engine
1. Cloud SQL
1. Cloud SQL Admin
1. Cloud Build
1. Cloud Resource Manager

Use [GCP Console](https://console.cloud.google.com/) or `gcloud` command line interface in [Cloud Shell](https://cloud.google.com/shell/docs/) to [enable the required services](https://cloud.google.com/service-usage/docs/enable-disable) . 

To enable the required services using `gcloud`:
1. Start GCP [Cloud Shell](https://cloud.google.com/shell/docs/)
2. Make sure that **Cloud Shell** is configured to use your project
```
PROJECT_ID=[YOUR_PROJECT_ID]

gcloud config set project $PROJECT_ID
```

3. Enable services
```
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
```

3. After the services are enabled, grant the Cloud Build service account the Project Editor role.
```
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
CLOUD_BUILD_SERVICE_ACCOUNT="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$CLOUD_BUILD_SERVICE_ACCOUNT \
  --role roles/editor
```


## Creating an **AI Platform Notebooks** instance

You will use a custom container image configured for KFP/TFX development as an environment for your instance. The image is a derivative of the standard TensorFlow 1.15  [AI Deep Learning Containers](https://cloud.google.com/ai-platform/deep-learning-containers/docs/) image.

### Building the custom docker image:

1. In **Cloud Shell**,  create a working folder in your `home` directory
```
cd
mkdir lab-workspace
cd lab-workspace
```

2. Create requirements file
```
cat > requirements.txt << EOF
absl-py<0.9
google-resumable-media<0.5.0dev
httplib2<=0.12.0
scikit-learn<0.22
pandas<1.0.0
cloudpickle==1.1.1
tfx==0.21.0rc0
kfp==0.2.2
tensorboard~=2.1.0
EOF
```

3. Create Dockerfile 
```
cat > Dockerfile << EOF
FROM gcr.io/deeplearning-platform-release/tf2-cpu.2-1
RUN apt-get update -y && apt-get -y install kubectl
COPY requirements.txt .
RUN pip install -U -r requirements.txt --ignore-installed PyYAML==3.13
EOF
```

3. Build the image and push it to your project's **Container Registry**

```
IMAGE_NAME=mlops-dev
TAG=latest
IMAGE_URI="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}"

gcloud builds submit --timeout 15m --tag ${IMAGE_URI} .
```

### Provisioning an AI Platform notebook instance

You can provision an instance of **AI Platform Notebooks** using the custom container image created in the previous steps using   [the GCP Console](https://cloud.google.com/ai-platform/notebooks/docs/custom-container) or using the `gcloud` command. To provision the instance using `gcloud`.

```
ZONE=[YOUR_ZONE]
INSTANCE_NAME=[YOUR_INSTANCE_NAME]

IMAGE_FAMILY="common-container"
IMAGE_PROJECT="deeplearning-platform-release"
INSTANCE_TYPE="n1-standard-4"
METADATA="proxy-mode=project_editors,container=$IMAGE_URI"

gcloud compute instances create $INSTANCE_NAME \
    --zone=$ZONE \
    --image-family=$IMAGE_FAMILY \
    --machine-type=$INSTANCE_TYPE \
    --image-project=$IMAGE_PROJECT \
    --maintenance-policy=TERMINATE \
    --boot-disk-device-name=${INSTANCE_NAME}-disk \
    --boot-disk-size=100GB \
    --boot-disk-type=pd-ssd \
    --scopes=cloud-platform,userinfo-email \
    --metadata=$METADATA
```


### Accessing JupyterLab IDE

After the instance is created, you can connect to [JupyterLab](https://jupyter.org/) IDE by clicking the *OPEN JUPYTERLAB* link.

