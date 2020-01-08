# Orchestrating model training and deployment with TFX and Cloud AI Platform

In this lab you will develop and operationalize a TFX pipeline that uses Kubeflow Pipelines for orchestration and Cloud Dataflow and Cloud AI Platform for data processing, training, and deployment:

1. In Exercise 1, you will review and understand the pipeline's source code - also referred to as the pipeline's DSL.

1. In Exercise 2, you will use **TFX CLI** to deploy the pipeline and submit pipeline runs.

1. In Exercise 3, you will author a **Cloud Build** CI/CD workflow that automates deployment.

1. In Exercise 4, you will integrate your CI/CD workflow with **GitHub**.


## Lab scenario

You will be working with a variant of the [Online News Popularity](https://archive.ics.uci.edu/ml/datasets/online+news+popularity) dataset, which summarizes a heterogeneous set of features about articles published by Mashable in a period of two years. The goal is to predict how popular the article will be on social networks. Specifically, in the original dataset the objective was to predict the number of times each article will be shared on social networks. In this variant, the goal is to predict the article's popularity percentile. For example, if the model predicts a score of 0.7, then it means it expects the article to be shared more than 70% of all articles.

The pipeline implements a typical TFX workflow as depicted on the below diagram:

![Lab 14 diagram](../images/lab-14-diagram.png).

The source data in a CSV file format is in the GCS bucket.

The TFX `ExampleGen`, `StatisticsGen`, `ExampleValidator`, `SchemaGen`, `Transform`, and `Evaluator` components use Cloud Dataflow as an execution engine. The `Trainer` and `Pusher` components use AI Platform Training and Prediction services.


## Lab setup

### AI Platform Notebook configuration
You will use the **AI Platform Notebooks** instance configured with a custom container image. To prepare the **AI Platform Notebooks** instance:

1. In **Cloud Shell**, navigate to the `lab-00-environment-setup/notebook-images/tf115-tfx015-kfp136` folder.
2. Build the container image
```
./build.sh
```
3. Provision the **AI Platform Notebook** instance based on a custom container image, following the  [instructions in AI Platform Notebooks Documentation](https://cloud.google.com/ai-platform/notebooks/docs/custom-container). In the **Docker container image** field, enter the following image name: `gcr.io/[YOUR_PROJECT_NAME]/tfx-kfp-dev:TF115-TFX015-KFP136`.

4. After the **AI Platform Notebooks** instance is ready, *open JupyterLab*.

5. Open a new terminal in **JupyterLab** and clone this repo under the `home` directory
```
cd /home
git clone https://github.com/jarokaz/mlops-labs.git
```

### Lab dataset
This lab uses the the [Online News Popularity](https://archive.ics.uci.edu/ml/datasets/online+news+popularity) dataset. The pipeline is designed to ingest the data from the GCS location in your project. To create the GCS bucket and upload the dataset:

1. From the *JupyterLab* terminal create the GCS bucket.
```
PROJECT_ID=[YOUR_PROJECT_ID]
BUCKET_NAME=gs://${PROJECT_ID}-lab-14
gsutil mb -p $PROJECT_ID $BUCKET_NAME
```

2. Upload the `online_news` dataset to the GCS bucket
```
gsutil cp gs://workshop-datasets/online_news/full/data.csv $BUCKET_NAME/online_news/data.csv 
```



## Lab Exercises
### Exercise 1  - Understanding the pipeline's DSL.

Follow the instructor who will walk you through the pipeline's DSL.

As described by the instructor, the pipeline in this lab uses a custom docker image that is a derivative of a base `tensorflow/tfx:0.15.0` image from [Docker Hub](https://hub.docker.com/r/tensorflow/tfx). The base `tfx` image includes TFX v0.15 and TensorFlow v2.0. The custom image modifies the base image by downgrading to TensorFlow to v1.15 and adding the `modules` folder with the `transform_train.py` file that contains data transformation and training code used by the pipeline's `Transform` and `Train` components.

The pipeline needs to use v1.15 of TensorFlow as AI Platform Prediction service, which is used as a deployment target, does not yet support v2.0 of TensorFlow.

### Exercise 2 - Compiling and running the pipeline
You can use **TFX CLI** to compile and deploy TFX pipelines and to submit pipeline runs. As the pipeline uses the custom image, the first step is to build the image and push it to your project's **Container Registry**. You will use **Cloud Build** to build the image.

First, activate the `tfx` Python environment that hosts TFX and TFX CLI.
```
source activate tfx
```

To create the image, navigate to the `pipeline-dsl` folder and execute the following commands:
```
PROJECT_ID=[YOUR_PROJECT_ID]
IMAGE_NAME=lab-14-tfx-image
TAG=latest
IMAGE_URI="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}"

gcloud builds submit --timeout 15m --tag ${IMAGE_URI} .
```

The pipeline's DSL retrieves the settings controlling how the pipeline is compiled from the environment variables. You need to set these variables before you start the compilation. To compile the pipeline using  **TFX CLI**:

```
export PROJECT_ID=[YOUR_PROJECT_ID]
export ARTIFACT_STORE_BUCKET=[YOUR_ARTIFACT_STORE_BUCKET]
export DATA_ROOT=$BUCKET_NAME/online_news
export PIPELINE_NAME=online_news_model_training
export GCP_REGION=us-central1
export TFX_IMAGE=$IMAGE_URI

tfx pipeline compile --pipeline_path pipeline_dsl.py 
```

The instructor will review the pipeline package file generated by the compiler.




### Exercise  3 - Authoring the CI/CD workflow that builds and deploy the KFP training pipeline

In this exercise you walk-through authoring a **Cloud Build** CI/CD workflow that automatically builds and deploys the KFP pipeline. The **Cloud Build** configuration uses both standard and custom [Cloud Build builders](https://cloud.google.com/cloud-build/docs/cloud-builders). The custom builder, which you build in the first part of the exercise, encapsulates **KFP CLI**. 

The version 1.37 of **KFP** added support for pipeline versions. However, this functionality is only available through **KFP UI**. It is not yet exposed through **KFP SDK**. In the current version of this exercise, you append the **Cloud Build** `$TAG_NAME` default substitution to the name of the pipeline to designate a pipeline version. When the pipeline versioning features is exposed through **KFP SDK** this exercise will be updated to use the feature.

1. Create a **Cloud Build** custom builder that encapsulates KFP CLI.
```
cd Lab-11-KFP-CAIP/cicd/kfp-cli
./build.sh
```
2. Follow the instructor who will walk you through  the Cloud Build configuration in:
```
Lab-11-KFP-CAIP/cicd/cloudbuild.yaml
```
3. Update the `build_pipeline.sh` script in the `Lab-11-KFP-CAIP/cicd` folder with your KFP inverting proxy host. You can retrieve the inverting proxy host name from the `inverse-proxy-config` ConfigMap. It will be under the `Hostname` key.
4. Manually trigger the CI/CD build:
```
./build_pipeline.sh
```
### Exercise 4 - Setting up GitHub integration
In this exercise you integrate your CI/CD workflow with **GitHub**, using [Cloud Build GitHub App](https://github.com/marketplace/google-cloud-build). 
You will set up a trigger that starts the CI/CD workflow when a new tag is applied to the **GitHub** repo managing the KFP pipeline source code. You will use a fork of this repo as your source GitHub repository.

1. [Follow the GitHub documentation](https://help.github.com/en/github/getting-started-with-github/fork-a-repo) to fork this repo
2. Connect the fork you created in the previous step to your Google Cloud project and create a trigger following the [Creating GitHub app trigger](https://cloud.google.com/cloud-build/docs/create-github-app-triggers) article. Configure your trigger using the below configuration as a template:

![Configure trigger](../images/configure_trigger.png)

Use the following values for the substitution variables:

|Variable|Value|
|--------|-----|
|_BASE_IMAGE_NAME|base_image|
|_COMPONENT_URL_SEARCH_PREFIX|https://raw.githubusercontent.com/kubeflow/pipelines/0.1.38/components/gcp/|
|_INVERTING_PROXY_HOST|[Your inverting proxy host]|
|_PIPELINE_DSL|covertype_training_pipeline.py|
|_PIPELINE_FOLDER|Lab-11-KFP-CAIP/pipelines|
|_PIPELINE_NAME|covertype_training_deployment|
|_PIPELINE_PACKAGE|covertype_training_pipeline.yaml|
|_PYTHON_VERSION|3.5|
|_RUNTIME_VERSION|1.14|
|_TRAINER_IMAGE_NAME|trainer_image|


3. To start an automated build [create a new release of the repo in GitHub](https://help.github.com/en/github/administering-a-repository/creating-releases).

### Exercise 5 - Integrating the KFP pipeline with the upstream data management pipeline
