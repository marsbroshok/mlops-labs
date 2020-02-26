# Continuous training with scikit-learn and Cloud AI Platform

This series of hands on labs guides you through the process of implementing a **Kubeflow Pipelines (KFP**) continuous training pipeline that automates training and deployment of a **scikit-learn** model. 

The below diagram represents the workflow orchestrated by the pipeline.

![Training pipeline](/images/kfp-caip.png).

1. The source data is in BigQuery
2. BigQuery is used to prepare training, evaluation, and testing data splits, 
3. AI Platform Training is used to tune hyperparameters and train a scikit-learn model, and
4. The model's performance is validated against a configurable performance threshold
4. If the model meets or exceeds the performance requirements it is deployed as an online service using AI Platform Prediction

## Scenario
The ML model utilized in the labs  is a multi-class classification model that predicts the type of forest cover from cartographic data. The model is trained on the [Covertype Data Set](/datasets/covertype/README.md) dataset.

## Lab exercises
### Lab 01 - Using custom containers with AI Platform Training
In this lab, you will develop, package as a docker image, and run on AI Platform Training a training application that builds a **scikit-learn** classifier. The goal of this lab is to understand and codify the steps of the machine learning workflow that will be orchestrated by the continuous training pipeline.


### Lab 02 - Orchestrating model training and deployment with Kubeflow Pipelines and Cloud AI Platform
In this lab, you will author, deploy, and run a **Kubeflow Pipelines (KFP)** pipeline that automates ML workflow steps you experminted with in the first lab.

### Lab 03 - CI/CD for a KFP pipeline
In this lab, you will walk through authoring of a **Cloud Build** CI/CD workflow that automates the process of building and deploying of the KFP pipeline authored in the second lab. You will also integrate the **Cloud Build** workflow with **GitHub**.

## Lab setup
Before proceeding with the lab exercises you need to set up the lab environment and prepare the lab dataset.

### Preparing the lab environment
### Preparing the lab dataset



