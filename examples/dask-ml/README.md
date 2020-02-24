# Parallel hyperparameter tuning with `scikit-learn` and `dask-ml`

This code sample demonstrates how to run a parallel hyperparameter tuning regime for [scikit-learn](https://scikit-learn.org/stable/) using [dask-ml](https://ml.dask.org/index.html) - a library for distributed and parallel machine learning.

The sample uses very basic features of `dask-ml`, specifically the [local distributed scheduler](https://docs.dask.org/en/latest/setup/single-distributed.html) and the [dask_ml.model_selection.GridSearchCV](https://ml.dask.org/hyper-parameter-search.html) class. To further improve performance on large, multi-CPU and high memory machines, you can consider utilizing other features of `dask-ml` like [parallel preprocessing](https://ml.dask.org/preprocessing.html), and [parallel estimators](https://ml.dask.org/glm.html)

The sample walks you through two scenarios:
- Running a parallel hypertuning job locally on a multi-CPU [Google Cloud Platform AI Platform Notebooks](https://cloud.google.com/ai-platform-notebooks) instance
- Running a parallel hypertuning job using [Google Cloud AI Platfom Training](https://cloud.google.com/ai-platform/training/docs/overview).

Before proceeding, you need a [Project Editor or Project Owner](https://cloud.google.com/iam/docs/understanding-roles) access to a [GCP Project](https://cloud.google.com/docs/overview) with the following **Cloud Services** enabled:
- Compute Engine
- Cloud Build
- AI Platform Training and Prediction

Use [GCP Console](https://console.cloud.google.com/) or `gcloud` command line interface in [Cloud Shell](https://cloud.google.com/shell/docs/) to [enable the required services](https://cloud.google.com/service-usage/docs/enable-disable). 

## Running a parallel hypertuning job locally on a multi-CPU AI Platform Notebooks instance

### Creating an instance of AI Platform Notebooks 
In this step you will create an instance of [AI Platform Notebooks](https://cloud.google.com/ai-platform-notebooks) using a custom container image. The custom container image is a derivative of the standard Python [Deep Learning Container](https://cloud.google.com/ai-platform/deep-learning-containers/) extended with [dask-ml](https://pypi.org/project/dask-ml/) and [fire](https://google.github.io/python-fire/guide/) Python packages.

You will create the custom image and provision the instance using [Google Cloud Platform Cloud Shell](https://cloud.google.com/shell).

1. Launch [Cloud Shell](https://cloud.google.com/shell/docs/launching-cloud-shell)
2. Create a temporary workspace folder in you home directory
```
cd
mkdir temp-workspace
cd temp-workspace
```
3. Create the Dockerfile for the custom image
```
cat > Dockerfile << EOF
FROM gcr.io/deeplearning-platform-release/base-cpu
RUN pip install -U fire dask-ml
EOF
```
4. Build the image using [Cloud Build](https://cloud.google.com/cloud-build). Make sure to use your project ID to set the `PROJECT_ID` environmental variable
```
PROJECT_ID=[YOUR_PROJECT_ID]
gcloud config set project $PROJECT_ID

IMAGE_NAME=dask-ml
TAG=latest
IMAGE_URI="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}"

gcloud builds submit --timeout 15m --tag ${IMAGE_URI} .
```
5. Provision the notebook instance. Maker sure to set the `INSTANCE_NAME` and `ZONE` environmental variables to your settings.
```
INSTANCE_NAME=[YOUR_INSTANCE_NAME]
ZONE=[YOUR_ZONE]

IMAGE_FAMILY="common-container"
IMAGE_PROJECT="deeplearning-platform-release"
INSTANCE_TYPE="n1-standard-16"
METADATA="proxy-mode=service_account,container=$IMAGE_URI"

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
```

### Connecting to JupyterLab on the instance
After the instance is created you can connect to [JupyterLab](https://jupyter.org/):
1. Go to the **AI Platform Notebooks** page in the Google Cloud Console.
https://console.cloud.google.com/ai-platform/notebooks/instances?_ga=2.54220904.1157225642.1581788166-681008261.1557843199&_gac=1.170534164.1582425753.EAIaIQobChMIt627m9Pm5wIVex-tBh3NFw-gEAAYASAAEgIXOvD_BwE
2. Select **Open JupyterLab** for the instance you created

### Running the hyperparameter job locally
To run the distributed hyperparameter job locally:
1. Open the **JupyterLab** terminal
2. Clone this repo
```
cd /home
git clone https://github.com/jarokaz/joblib.git
cd joblib
```
3. Review the `run_locally.sh` script. Note how to configure the number of workers and threads. 
4. Run the hyperparameter tuning script
```
./run_locally.sh
```
5. If you want you can monitor the resource usage by opening another JupyterLab terminal and starting the Linux `top` command

## Running a parallel hypertuning job using Google Cloud AI Platfom Training

There are many options for running the script similar to `hypertune.py` as a batch job on GCP. You can schedule it on a GCP VM, or package it as a container image and run it on Google Kubernetes Cluster (GKE). 

In this example you will use the [custom containers feature](https://cloud.google.com/ai-platform/training/docs/using-containers) of **AI Platform Training**.


1. Open the **JupyterLab** terminal
2. Make sure that you are in the root folder of the example
```
cd /home/joblib
```
3. Package the training script as a docker container image
```
cat > Dockerfile << EOF
FROM gcr.io/deeplearning-platform-release/base-cpu
RUN pip install -U fire dask-ml
WORKDIR /app
COPY hypertune.py .

ENTRYPOINT ["python", "hypertune.py"]
EOF
```
4. Build the hyperparameter tuning container image using **Cloud Build**
```
PROJECT_ID=$(gcloud config get-value core/project)
IMAGE_NAME=dask_ml_trainer
IMAGE_TAG=latest
IMAGE_URI=gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG

gcloud builds submit --tag $IMAGE_URI .
```
5. Create a Google Cloud Storage bucket to be use by the **AI Platform Training** job
```
JOB_BUCKET=gs://[YOUR_BUCKET_NAME]

gsutil mb $JOB_BUCKET
```
6. Review and update the `run_on_caip.sh` script. Make user that the `IMAGE_URI` and `JOB_BUCKET` variables are set to your settings.
7. Start the job by running the `run_on_caip.sh` script
```
./run_on_caip.sh
```
7. You can monitor the job using [the `gcloud` command or GCP Console](https://cloud.google.com/ai-platform/training/docs/monitor-training)
