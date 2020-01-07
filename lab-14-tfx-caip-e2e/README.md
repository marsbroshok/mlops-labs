# Running a TFX pipeline on Kubeflow Pipelines and Cloud AI Platform

This lab demonstrates how develop a TFX pipeline that utilizes Cloud AI Platform services for processing and orchestration.

The lab requiries a full MLOps environment as described in *Lab-00-Environment-Setup* including an **AI Platform Notebooks** instance based on a custom container image.

## Lab setup
AI Platform Notebook configuration
You will use the AI Platform Notebooks instance configured with a custom container image. To prepare the AI Platform Notebooks instance:

In Cloud Shell, navigate to the Lab-00-Environment-Setup/notebook-images/tf115-tfx015-kfp136 folder.
Build the container image
./build.sh
Provision the AI Platform Notebook instance based on a custom container image, following the instructions in AI Platform Notebooks Documentation. In the Docker container image field, enter the following image name: gcr.io/[YOUR_PROJECT_NAME/tfx-kfp-dev:TF115-TFX015-KFP136

