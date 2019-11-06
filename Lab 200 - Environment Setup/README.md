# Setting up a lab environment for 200 series labs.

The environment for the 200-series labs is depicted on the below diagram.

![Reference topolgy](/images/environment.png)

The core services in the environment are:
- AI Platform Notebooks - ML experimentation and development
- AI Platform Training - scalable, serverless model training
- AI Platform Prediction - scalable, serverless model serving
- Cloud Storage - unified object storage

All required services are provisioned in the same [Google Cloud Project](https://cloud.google.com/storage/docs/projects). Before proceeding make sure that your account has access to the project and is assigned to the **Owner** or **Editor** role.

## Enabling the required cloud services

The following GCP Cloud APIs  must be enabled in your project:
1. Compute Engine
1. Cloud Storage
1. BigQuery
1. Cloud Machine Learning Engine

Use [GCP Console](https://console.cloud.google.com/) or `gcloud` command line interface in [Cloud Shell](https://cloud.google.com/shell/docs/) to [enable the required services](https://cloud.google.com/service-usage/docs/enable-disable) . 

You can use the `enable_apis.sh` script to enable the required services from **Cloud Shell**.
```
./enable.sh
```

## Provisioning and AI Platform Notebooks instance
During the labs, you use an **AI Platform Notebooks** instance as your primary development environment. Different labs use different configurations of **AI Platform Notebooks**. Make sure to review the README file for each lab and provision the right configuration before starting a given lab.

To create a notebook instance follow the [instructions in AI Platform Notebooks Documentation](https://cloud.google.com/ai-platform/notebooks/docs/create-new).
