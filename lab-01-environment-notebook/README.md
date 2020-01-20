# Setting up an MLOps environment on GCP.

The labs in this repo are designed to run in a reference MLOps environment. The environment is configured to support effective development and operationalization of production grade ML workflows.

![Reference topolgy](/images/lab_300.png)

The core services in the environment are:
- AI Platform Notebooks - ML experimentation and development
- AI Platform Training - scalable, serverless model training
- AI Platform Prediction - scalable, serverless model serving
- Dataflow - distributed data processing
- BigQuery - analytics data warehouse
- Cloud Storage - unified object storage
- TensorFlow Extended/Kubeflow Pipelines (TFX/KFP) - machine learning pipelines
- Cloud SQL - machine learning metadata  management
- Cloud Build - CI/CD
    
In this lab, you will create an **AI Platform Notebook** instance using a custom container image optimized for TFX/KFP development. In the **lab-02-environment-kfp** lab, you will provision a lightweight deployment of **Kubeflow Pipelines**.

In the reference environment, all services are provisioned in the same [Google Cloud Project](https://cloud.google.com/storage/docs/projects). Before proceeding make sure that your account has access to the project and is assigned to the **Owner** or **Editor** role.

Although you can run the below commands from any workstation configured with *Google Cloud SDK*, the following instructions have been tested on GCP [Cloud Shell](https://cloud.google.com/shell/).

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

2. Execute the below command.
```
gcloud services enable cloudbuild.googleapis.com \
	container.googleapis.com \
	cloudresourcemanager.googleapis.com \
	iam.googleapis.com \
	containerregistry.googleapis.com \
	containeranalysis.googleapis.com \
	ml.googleapis.com \
	sqladmin.googleapis.com \
	dataflow.googleapis.com \
	automl.googleapis.com
```

*Make sure that the Cloud Build service account (that was created when you enabled the Cloud Build service) is granted the Project Editor role.*


## Creating an **AI Platform Notebooks** instance

You will use a custom container image configured for KFP/TFX development as an environment for your instance. The image is a derivative of the standard TensorFlow 1.15  [AI Deep Learning Containers](https://cloud.google.com/ai-platform/deep-learning-containers/docs/) image.

To create a Dockerfile describing the image:

1. Start GCP [Cloud Shell](https://cloud.google.com/shell/docs/)

2. Create a working folder in your `home` directory
```
cd
mkdir lab-01-workspace
cd lab-01-workspace
```

3. Create the Dockerfile
```
cat > Dockerfile << EOF
FROM gcr.io/deeplearning-platform-release/tf-cpu.1-15
RUN apt-get update -y && apt-get -y install kubectl
RUN cd /usr/local/bin \
&& wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.3.0/kustomize_v3.3.0_linux_amd64.tar.gz \
&& tar xvf kustomize_v3.3.0_linux_amd64.tar.gz \
&& rm kustomize_v3.3.0_linux_amd64.tar.gz
RUN pip install -U six==1.12 apache-beam==2.16 pyarrow==0.14.0 tfx-bsl==0.15.1 \
&& pip install -U tfx==0.15 \
&& RELEASE=0.1.36 \
&& pip install https://storage.googleapis.com/ml-pipeline/release/$RELEASE/kfp.tar.gz
EOF
```

To build the image and push it to your project's **Container Registry**

```
PROJECT_ID=$(gcloud config get-value core/project)
IMAGE_NAME=mlops-dev
TAG=TF115-TFX015-KFP136

IMAGE_URI="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}"

gcloud builds submit --timeout 15m --tag ${IMAGE_URI} .
```




