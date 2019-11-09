# Setting up a lab environment for 100 series labs.

**AI Platform Notebooks**, **AI Platform Training and Prediction**, **Dataflow**, and **BigQuery** are the primary services used in the 100 series labs. 

![Reference topolgy](/images/lab_200.png)


In the lab environment, all services are provisioned in the same [Google Cloud Project](https://cloud.google.com/storage/docs/projects). Before proceeding make sure that your account has access to the project and is assigned to the **Owner** or **Editor** role.

## Enabling the required cloud services

<<<<<<< HEAD
In addition to the [services enabled by default](https://cloud.google.com/service-usage/docs/enabled-service), the following additional services must be enabled for the 100-series labs:

1. Compute Engine - `compute.googleapis.com`
1. AI Platform Training & Prediction - `ml.googleapis.com`
1. Cloud Dataflow - `dataflow.googleapis.com`

=======
The following GCP Cloud APIs  must be enabled in your project:
1. Compute Engine
1. Cloud Storage
1. BigQuery
1. Cloud Machine Learning Engine
1. Dataflow
>>>>>>> c888357f0749f16e1e8ba002bc3906676363c3c4

Use [GCP Console](https://console.cloud.google.com/) or `gcloud` command line interface in [Cloud Shell](https://cloud.google.com/shell/docs/) to [enable the required services](https://cloud.google.com/service-usage/docs/enable-disable) . 

You can use the `enable_apis.sh` script to enable the required services from **Cloud Shell**.
```
./enable.sh
```

## Provisioning and AI Platform Notebooks instance
Different labs use different configurations of **AI Platform Notebooks**. Make sure to review the README file for a given lab and provision the right configuration before proceeding.

To create a notebook instance follow the [instructions in AI Platform Notebooks Documentation](https://cloud.google.com/ai-platform/notebooks/docs/create-new).
