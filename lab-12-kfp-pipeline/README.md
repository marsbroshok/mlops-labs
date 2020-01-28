# Orchestrating model training and deployment with Kubeflow Pipelines (KFP) and Cloud AI Platform

In this lab, you will develop, deploy, and run a KFP pipeline that orchestrates **BigQuery** and **Cloud AI Platform** services to train a **scikit-learn** model.


## Lab scenario

This lab uses the same scenario and training application as `lab-11-caip-containers`. Since the focus of this lab is on developing and deploying a KFP pipeline rather than on specifics of the training code, the `lab-11-caip-containers` lab is not a required pre-requisite. However, it is highly recommend to walk through `lab-11-caip-container` before starting this lab, especially if you don't have previous experience with using custom containers with AI Platform Training.

During the lab, the instructor will walk you through key parts of a typical KFP pipeline, including pre-built components, custom components and a pipeline definition in KFP Domain Specific Language (DSL). You will also use KFP compiler and KFP CLI to compile the pipeline's DSL, upload the pipeline package to the KFP environment, and trigger pipeline runs.


The pipeline you develop in the lab orchestrates GCP managed services. The source data is in BigQuery. The pipeline uses:
- BigQuery to prepare training, evaluation, and testing data splits, 
- AI Platform Training to run a custom container with data preprocessing and training code, and
- AI Platform Prediction as a deployment target. 

The below diagram represents the workflow orchestrated by the pipeline.

![Training pipeline](../images/kfp-caip.png).

## Lab setup

### AI Platform Notebook and KFP environment
Before proceeding with the lab, you must set up an **AI Platform Notebook** instance and a KFP environment as detailed in `lab-01-environment-notebook` and `lab-02-environment-kfp`

### Lab dataset
This lab uses the [Covertype Dat Set](../datasets/covertype/README.md). The pipeline developed in the lab sources the dataset from BigQuery. Before proceeding with the lab upload the dataset to BigQuery:

1. Open new terminal in you **JupyterLab**

2. Create the BigQuery dataset and upload the `covertype.csv` file.
```
PROJECT_ID=[YOUR_PROJECT_ID]
DATASET_LOCATION=US
DATASET_ID=lab_11
TABLE_ID=covertype
DATA_SOURCE=gs://workshop-datasets/covertype/full/dataset.csv
SCHEMA=Elevation:INTEGER,\
Aspect:INTEGER,\
Slope:INTEGER,\
Horizontal_Distance_To_Hydrology:INTEGER,\
Vertical_Distance_To_Hydrology:INTEGER,\
Horizontal_Distance_To_Roadways:INTEGER,\
Hillshade_9am:INTEGER,\
Hillshade_Noon:INTEGER,\
Hillshade_3pm:INTEGER,\
Horizontal_Distance_To_Fire_Points:INTEGER,\
Wilderness_Area:STRING,\
Soil_Type:STRING,\
Cover_Type:INTEGER

bq --location=$DATASET_LOCATION --project_id=$PROJECT_ID mk --dataset $DATASET_ID

bq --project_id=$PROJECT_ID --dataset_id=$DATASET_ID load \
--source_format=CSV \
--skip_leading_rows=1 \
--replace \
$TABLE_ID \
$DATA_SOURCE \
$SCHEMA
```

### GCS bucket
Create the GCS bucket that will be used as a staging area during the lab.
```
BUCKET_NAME=gs://${PROJECT_ID}-staging
gsutil mb -p $PROJECT_ID $BUCKET_NAME
```
## Lab Exercises

Follow the instructor who will walk you through the lab. The high level summary of the lab flow is as follows.


### Authoring the pipeline

Your pipeline uses a mix of custom and pre-build components.

- Pre-build components. The pipeline uses the following pre-build components that are included with KFP distribution:
    - [BigQuery query component](https://github.com/kubeflow/pipelines/tree/0.1.36/components/gcp/bigquery/query)
    - [AI Platform Training component](https://github.com/kubeflow/pipelines/tree/0.1.36/components/gcp/ml_engine/train)
    - [AI Platform Deploy component](https://github.com/kubeflow/pipelines/tree/0.1.36/components/gcp/ml_engine/deploy)
- Custom components. The pipeline uses two custom helper components that encapsulate functionality not available in any of the pre-build components. The components are implemented using the KFP SDK's [Lightweight Python Components](https://www.kubeflow.org/docs/pipelines/sdk/lightweight-python-components/) mechanism. The code for the components is in the `helper_components.py` file:
    - **Retrieve Best Run**. This component retrieves the tuning metric and hyperparameter values for the best run of the AI Platform Training hyperparameter tuning job.
    - **Evaluate Model**. This component evaluates the *sklearn* trained model using a provided metric and a testing dataset. 


The workflow implemented by the pipeline is defined using a Python based KFP Domain Specific Language (DSL). The pipeline's DSL is in the `covertype_training_pipeline.py` file.

### Building the training image

The training step in the pipeline employes the AI Platform Training component to schedule a  AI Platform Training job in a custom container. If you walked through the `lab-11-caip-trainer` lab the trainer image was already pushed to your project's Container Registry. If you did not, you can build and push the image using the below commands.   Make sure to update the Dockerfile in the `trainer_image` folder with the URI pointing to your Container Registry.

```
PROJECT_ID=[YOUR_PROJECT_ID]
IMAGE_NAME=trainer_image
TAG=latest
IMAGE_URI="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}"

gcloud builds submit --timeout 15m --tag ${IMAGE_URI} trainer_image

```

### Building the base image for custom components
The custom components used by the pipeline are run in the context of a base image. To maintain the consistency between the development environment (AI Platform Notebooks) and the components' runtime environment the component base image is a derivative of the image used by the AI Platform Notebooks instance - `gcr.io/[YOUR_PROJECT_ID]/mlops-dev:TF115-TFX015-KFP136`. 

To build and push the base image execute the below commands. Make sure to update the Dockerfile in the `base_image` folder with the URI pointing to your Container Registry.


```
IMAGE_NAME=base_image
TAG=latest
IMAGE_URI="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}"

gcloud builds submit --timeout 15m --tag ${IMAGE_URI} base_image
```



### Compiling and deploying the pipeline

Before deploying to the KFP runtime environment, the pipeline's DSL has to be compiled into a pipeline runtime format, also refered to as a pipeline package.  The current version of the runtime format is based on [Argo Workflow](https://github.com/argoproj/argo), which is expressed in YAML. 

You can compile the DSL using an API from the **KFP SDK** or using the **KFP** compiler.

To compile the pipeline DSL using **KFP** compiler. From the root folder of this lab, execute the following commands.

```
export PROJECT_ID=[YOUR_PROJECT_ID]
export BASE_IMAGE=gcr.io/$PROJECT_ID/base_image:latest
export TRAINER_IMAGE=gcr.io/$PROJECT_ID/trainer_image:latest
export COMPONENT_URL_SEARCH_PREFIX=https://raw.githubusercontent.com/kubeflow/pipelines/0.1.36/components/gcp/
export RUNTIME_VERSION=1.14
export PYTHON_VERSION=3.5

dsl-compile --py covertype_training_pipeline.py --output covertype_training_pipeline.yaml
```

The result is the `covertype_training_pipeline.yaml` file. This file needs to deployed to the KFP runtime before pipeline runs can be triggered. You can deploy the pipeline package using an API from the **KFP SDK** or using the **KFP** Command Line Interface (CLI).

To upload the pipeline package using **KFP CLI**:

```
INVERSE_PROXY_HOSTNAME=[YOUR_INVERSE_PROXY_HOSTNAME]
PIPELINE_NAME=covertype_classifier_training

kfp --endpoint $INVERSE_PROXY_HOSTNAME pipeline upload \
-p $PIPELINE_NAME \
covertype_training_pipeline.yaml
```
Where [YOUR_INVERSE_PROXY_HOST] is the hostname of the inverse proxy providing access to your KFP environment. The hostname is stored in the `inverse-proxy-config` ConfigMap in the Kubernetes namespace where you deployed KFP in `lab-02-environment-kfp`.

You can retrieve the hostname using the following commands.

```
gcloud container clusters get-credentials [YOUR_GKE_CLUSTER] --zone [YOUR_ZONE]
kubectl describe configmap inverse-proxy-config -n [YOUR_NAMESPACE] | grep "googleusercontent.com"
```

You can double check that the pipeline was uploaded by listing the pipelines in your KFP environment.

```
kfp --endpoint $INVERSE_PROXY_HOSTNAME pipeline list
```


### Submitting pipeline runs

You can trigger pipeline runs using an API from the KFP SDK or using KFP CLI. To submit the run using KFP CLI, execute the following commands. Notice how the pipeline's parameters are passed to the pipeline run.


```
PROJECT_ID=[YOUR_PROJECT_ID]
EXPERIMENT_NAME=Covertype_Classifier_Training
RUN_ID=Run_001
PIPELINE_ID=[YOUR_PIPELINE_ID]
GCS_STAGING_BUCKET=[YOUR_GCS_STAGING_BUCKET]
REGION=[YOUR_REGION]
INVERSE_PROXY_HOSTNAME=[YOUR_INVERSE_PROXY_HOSTNAME]

kfp --endpoint $INVERSE_PROXY_HOSTNAME run submit \
-e Covertype_Classifier_Training \
-r Run_201 \
-p $PIPELINE_ID \
project_id=$PROJECT_ID \
gcs_root=$GCS_STAGING_BUCKET \
region=$REGION \
source_table_name=lab_11.covertype \
dataset_id=splits \
evaluation_metric_name=accuracy \
evaluation_metric_threshold=0.69 \
model_id=covertype_classifier \
version_id=v0.3 \
replace_existing_version=True
```

where

- EXPERIMENT_NAME is set to the experiment used to run the pipeline. You can choose any name you want. If the experiment does not exist it will be created by the command
- RUN_ID is the name of the run. You can use an arbitrary name
- PIPELINE_ID is the id of your pipeline. Use the value retrieved by the   `kfp pipeline list` command
- GCS_STAGING_BUCKET is the GCS bucket used by the pipeline to store intermediate files. Use the bucket created during the lab setup
- REGION is the compute region for AI Platform Training and Prediction. We recommend using the same region where your KFP environment is deployed.

You should be already familiar with these and other parameters passed to the command. If not go back and review the pipeline code.


### Monitoring the run

You can monitor the run using KFP UI. Follow the instructor who will walk you through the KFP UI and monitoring techniques.

To access the KFP UI in your environment use the following URI:

https://[YOUR_INVERSE_PROXY_HOSTNAME]


*Note that your pipeline may fail due to the bug in a BigQuery component that does not handle certain race conditions. If you observe the pipeline failure retry the run from the KFP UI*

