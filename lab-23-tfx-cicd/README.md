# CI/CD for TFX pipelines

In this lab you will walk through authoring of a Cloud Build CI/CD workflow that automatically builds and deploys a TFX pipeline. You will also integrate your workflow with GitHub by setting up a trigger that starts the workflow when a new tag is applied to the GitHub repo hosting the pipeline's code.


## Lab scenario

This lab uses the TFX code developed in lab-22-tfx-pipeline.


## Lab setup

### AI Platform Notebooks and KFP environment

Before proceeding with the lab, you must set up an AI Platform Notebook instance and a KFP environment as detailed in lab-01-environment-notebook and lab-02-environment-kfp


## Lab Exercises

### Authoring the CI/CD workflow that builds and deploy the TFX training pipeline

In this exercise you review and trigger a **Cloud Build** CI/CD workflow that automates the process of compiling and deploying the KTFX pipeline. The **Cloud Build** configuration uses both standard and custom [Cloud Build builders](https://cloud.google.com/cloud-build/docs/cloud-builders). The custom builder, which you build in the first part of the exercise, encapsulates **TFX CLI**. 

As of version 1.36 of **KFP** there is no support for pipeline versions. It will be added in future releases, with the intial functionality introduced in version 1.37. In the lab, you append the **Cloud Build** `$TAG_NAME` default substitution to the name of the pipeline to designate a pipeline version. When the pipeline versioning features is exposed through **KFP SDK** this exercise will be updated to use the feature.

1. Create a **Cloud Build** custom builder that encapsulates TFX CLI.
```
cd cicd/tfx-cli
./build.sh
```
2. Follow the instructor who will walk you through  the Cloud Build configuration in:
```
cicd/cloudbuild.yaml
```
3. Update the `build_pipeline.sh` script in the `cicd` folder with your KFP inverting proxy host.

4. Manually trigger the CI/CD build:
```
./build_pipeline.sh
```
