# Orchestraiting model training and deployment with KFP and Cloud AI Platform

Developing a repeatable and reliable ML pipeline is a complex, multi-step process.

In most cases, you start by exploring the datasets and experimenting with data preprocessing and modeling routines in an interactive environment like Jupyter notebooks. When you zero in on a given approach you formalize your workflow by authoring an ML pipeline.

Today, the process of transitioning from an interactive notebook to an operationalized pipeline is not fully automated. You need to manually re-factor your code snippets in the notebook to ML Pipeline DSL. There is ongoing work in TFX and KFP initiatives to make the process more streamlined and eventually fully automated.

In this lab, you simulate this process by walking through the development of a KFP pipeline that orchrestrates BigQuery and Cloud AI Platform services to train and deploy a **scikit-learn model**:

1. In Part 1 of the lab, you will work in a Jupyter notebook to explore the data, prepare data extraction routines, and experiment with training and hyperparameter tuning code.

2. In Part 2, you will re-factor code snippets developed in the notebook into KFP components and a KFP pipeline.

3. In Part 3, you will develop a CI/CD workflow that automatically builds and deploys the KFP pipeline.


## Lab scenario

Using the [Covertype Data Set](../datasets/covertype/README.md) you will develop a multi-class classification model that predicts the type of forest cover from cartographic data. 

The source data is in BigQuery. The pipeline uses:
- BigQuery to prepare training, evaluation, and splits, 
- AI Platform Training to run a custom container with data preprocessing and training code, and
- AI Platform Prediction as a deployment target. The below diagram represents the workflow orchestrated by the pipeline.

![Training pipeline](../images/kfp-caip.png).

## Lab setup

### AI Platform Notebook configuration
You will use the **AI Platform Notebooks** instance configured with the `kfp136` image. To prepare the lab:
1. Create/use the **AI Platform Notebook** instance using the process described in [Lab-00-Environment-Setup](../Lab-00-Environment-Setup/README.md).
2. Open **JupyterLab** in your instance


### Lab dataset
This lab uses the [Covertype Dat Set](../datasets/covertype/README.md). The pipeline developed in the lab sources the dataset from BigQuery. Before proceeding with the lab upload the dataset to BigQuery:

1. Open new terminal in you **JupyterLab**
2. Clone this repo in the `home` folder
```
cd /home
git clone https://github.com/jarokaz/mlops-labs.git
```

3. Navigate to the datasets folder and upload the dataset to BigQuery
```
cd mlops-labs/datasets/covertype

PROJECT_ID=[YOUR_PROJECT_ID]
DATASET_LOCATION=US
DATASET_ID=lab_11
TABLE_ID=covertype
DATA_SOURCE=covertype.csv
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
```
BUCKET_NAME=gs://${PROJECT_ID}-lab-11
gsutil mb -p $PROJECT_ID $BUCKET_NAME
```

## Lab Part 1 - Experimentation
1. Walk through the `notebooks/covertype_experminentation.ipynb` notebook
## Lab Part 2 - KFP pipeline authoring
1. Review code in the `pipelines` folder
2. Navigate to the `pipelines` folder and compile the pipeline
```
export PROJECT_ID=mlops-workshop
export COMPONENT_URL_SEARCH_PREFIX=https://raw.githubusercontent.com/kubeflow/pipelines/0.1.36/components/gcp/
export BASE_IMAGE=gcr.io/deeplearning-platform-release/base-cpu
export TRAINER_IMAGE=gcr.io/$PROJECT_ID/trainer_image:latest
export RUNTIME_VERSION=1.14
export PYTHON_VERSION=3.5

dsl-compile --py covertype_training_pipeline.py --output covertype_training_pipeline.yaml
```
3. Configure GKE credentials
```
gcloud container clusters get-credentials mlops-workshop-cluster --zone us-central1-a
```
4. Run the pipeline
```
kfp run submit -e Covertype_Classifier_Training \
-r Run_201 \
-f covertype_training_pipeline.yaml \
project_id=mlops-workshop \
region=us-central1 \
source_table_name=lab_11.covertype \
gcs_root=gs://mlops-workshop-lab-11 \
dataset_id=splits \
evaluation_metric_name=accuracy \
evaluation_metric_threshold=0.69 \
model_id=covertype_classifier \
version_id=v0.3 \
replace_existing_version=True
```
## Lab Part 3 - CI/CD
### Manually triggerting the CI/CD JOB
1. Build the *kfp-cli* docker image
```
cd Lab-11-KFP-CAIP/cicd/kfp-cli
./build.sh
```
2. Review Cloud Build configuration
3. Trigger the CI/CD run
### Setting up GitHub integration
1. Fork this repo
2. Install **Cloud Build App** connect your GitHub repository to your Google Cloud project following the **Installing the Cloud Build App** section (and only this section) of the following instructions:
https://cloud.google.com/cloud-build/docs/create-github-app-triggers. When asked to create a push trigger at the end of the process skip it.
3. Create a new trigger on your repo by selecting the **Add trigger**  from the menu of actions:
![Add trigger](../images/add_trigger.png)
4. Configure your trigger using the below configuration as a template:
![Configure trigger](../images/configure_trigger.png)



