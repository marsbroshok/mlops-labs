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
DATA_SOURCE=gs://workshop-datasets/covertype/full/covertype.csv
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
Soil_Type:INTEGER,\
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
BUCKET_NAME=gs://${PROJECT_ID}-lab-11
gsutil mb -p $PROJECT_ID $BUCKET_NAME
```
## Lab Exercises

Follow the instructor who will explain how to author, deploy, and run a KFP pipeline. The high level summary of the topics that will be covered in detail by the instructor is as follows.


### Authoring a KFP pipeline

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

The training step in the pipeline employes the AI Platform Training component to schedule a  AI Platform Training job in a custom container. If you walked through the `lab-11-caip-trainer` lab the trainer image was already pushed to your project's Container Registry. If you did not, you can build and push the image using the below commands. From the `trainer_image` folder:
```

```




### Compiling and deploying the pipeline

Before deploying to the KFP runtime environment, the pipeline's DSL has to be compiled into a pipeline runtime format, also refered to as a pipeline package.  The current version of the runtime format is based on [Argo Workflow](https://github.com/argoproj/argo), which is expressed in YAML. 

You can compile the DSL using an API from the **KFP SDK** or using the **KFP** compiler.

To compile the pipeline DSL using **KFP** compiler. From the root folder of this lab, execute the following commands.

```
export PROJECT_ID=[YOUR_PROJECT_ID]
export COMPONENT_URL_SEARCH_PREFIX=https://raw.githubusercontent.com/kubeflow/pipelines/0.1.38/components/gcp/
export BASE_IMAGE=gcr.io/deeplearning-platform-release/base-cpu
export TRAINER_IMAGE=gcr.io/$PROJECT_ID/trainer_image:latest
export RUNTIME_VERSION=1.14
export PYTHON_VERSION=3.5

dsl-compile --py covertype_training_pipeline.py --output covertype_training_pipeline.yaml
```

The result is the `covertype_training_pipeline.yaml` file. This file needs to deployed to the KFP runtime before pipeline runs can be triggered. You can deploy the pipeline package using an API from the **KFP SDK** or using the **KFP** Command Line Interface (CLI).

To upload the pipeline package using **KFP CLI**:

```
```



3. Finally, you manually submit a pipeline run using **KFP CLI**.
```
kfp --endpoint [YOUR_INVERSE_PROXY_HOSTNAME] run submit \
-e Covertype_Classifier_Training \
-r Run_201 \
-f covertype_training_pipeline.yaml \
project_id=[YOUR_PROJECT_ID] \
gcs_root=[YOUR_STAGING_BUCKET] \
region=us-central1 \
source_table_name=lab_11.covertype \
dataset_id=splits \
evaluation_metric_name=accuracy \
evaluation_metric_threshold=0.69 \
model_id=covertype_classifier \
version_id=v0.3 \
replace_existing_version=True
```
4. You can monitor the run using KFP UI.

