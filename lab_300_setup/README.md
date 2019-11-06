# Setting up a lab environment for 300 series labs.

The environment for the 300-series labs is depicted on the below diagram.

![Reference topolgy](/images/environment.png)

The core services in the environment are:
- AI Platform Notebooks - ML experimentation and development
- AI Platform Training - scalable, serverless model training
- AI Platform Prediction - scalable, serverless model serving
- BigQuery - analytics data warehouse
- Cloud Storage - unified object storage
- Kubeflow Pipelines (KFP) - machine learning worklow orchestration
- Cloud SQL - machine learning metadata  management
    
All required services are provisioned in the same [Google Cloud Project](https://cloud.google.com/storage/docs/projects). Before proceeding make sure that your account has access to the project and is assigned to the **Owner** or **Editor** role.

## Enabling the required cloud services

The following GCP Cloud APIs  must be enabled in your project:
1. Compute Engine
1. Cloud Storage
1. Container Registry
1. BigQuery
1. Cloud Machine Learning Engine
1. IAM
1. Dataflow
1. Kubernetes Engine
1. Cloud SQL
1. Cloud SQL Admin
1. Cloud Build
1. Cloud Resource Manager

Use [GCP Console](https://console.cloud.google.com/) or `gcloud` command line interface in [Cloud Shell](https://cloud.google.com/shell/docs/) to [enable the required services](https://cloud.google.com/service-usage/docs/enable-disable) . 

You can use the `enable_apis.sh` script to enable the required services from **Cloud Shell**.
```
./enable.sh
```

*Make sure that the Cloud Build service account (that was created when you enabled the Cloud Build service) is granted the Kubernetes Engine Developer role.*

## Provisioning an AI Platform Notebook instance
You use an **AI Platform Notebooks** instance based on a custom container as your primary development environment. 

The process of creating the custom container image has been automated with  [Cloud Build](https://cloud.google.com/cloud-build/). To build the image and push it to your project's **Container Registry** run the `./build.sh` script from **Cloud Shell**.

After the build completes, follow the  [instructions in AI Platform Notebooks Documentation](https://cloud.google.com/ai-platform/notebooks/docs/custom-container) to create an **AI Platform Notebook** instance. In the **Docker container image** field, enter the following image name: `gcr.io/[YOUR_PROJECT_NAME/tfx-kfp-dev:latest`.





## Deploying Kubeflow Pipelines 

The Kubeflow Pipelines deployment is organized into two steps:
- Provisioning the infrastructure components required to run Kubeflow Pipelines
- Installing Kubeflow Pipelines services

### Provisioning the Kubeflow Pipelines infrastructure

The MVP infrastructure to support a lightweight deployment of Kubeflow Pipelines comprises the following GCP services:
- A VPC to host GKE cluster
- A GKE cluster to host KFP services
- A Cloud SQL managed MySQL instance to host KFP and ML Metadata databases
- A Cloud Storage bucket to host artifact repository
- GKE and KFP service accounts. The GKE service account is used by GKE nodes. The KFP service account is used by KFP pipelines.

The provisioning of the KFP infrastructure has been automated with Terraform. The Terraform HCL configurations can be found in the `terraform` folder.

To provision the infrastructure:

1. Open **Cloud Shell**
1. Update `terraform/terraform.tfvars` with your *Project ID*, *Region*, and *Name Prefix*. The *Name Prefix* value will be added to the names of provisioned resources including: GKE cluster name, GCS bucket name, Cloud SQL instance name.
1. Execute the updated configuration from the `terraform` folder
```
cd terraform
terraform init
terraform apply
```

## Installing Kubeflow Pipelines services

The deployment of Kubeflow Pipelines to the environment's GKE cluster has been automated with **Kustomize**. 
Before applying the provided **Kustomize** overlays you need to configure connection settings to Cloud SQL and GCS. 

### Configuring connections settings to Cloud SQL and Cloud Storage

The KFP services access the Cloud SQL instance through Cloud SQL Proxy. To enable this access path, the Cloud SQL Proxy needs to be configured with a private key of the KFP service account and the KFP services need access to the credentials of a Cloud SQL database user. The private key and the credentials are stored as Kubernetes secrets. The URIs to the GCS bucket and the Cloud SQL instance are stored in a Kubernetes ConfigMap.

*Note: In the current release of KFP, the Cloud SQL instance needs to be configured with the root user with no password. The instance created by the Terraform configuration conforms to his constraint. This will be mitigated in the upcoming releases.*

To configure connection settings:
1. Use Cloud Console or the `gcloud` [command](https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/keys/create)  to create and download a JSON type private key file for the KFP service user. If you provisioned the infrastructure with the provided Terraform configurations the user name is `[YOUR PREFIX]-kfp-cluster@[YOUR PROJECT ID].iam.gserviceaccount.com`. Rename the file to `application_default_credentials.json`. **Note that the `application_default_credentials.json` file contains sensitive information. Remeber to remove or secure the file after the installation process completes.**

2. Rename `gcp-configs.env.template` to `gcp-configs.env`. Replace the placeholders in the file with the values for your environment. Don't use the `gs://` prefix when configuring the *bucket_name*. If you provisioned the infrastructure with the provided Terraform configuration, the bucket name is `[YOUR_PREFIX]-artifact-store`. Use the following format for the *connection_name* - [YOUR PROJECT]:[YOUR REGION]:[YOUR INSTANCE NAME]. If you provisioned the infrastructure with the provided Terraform configuration the instance name is `[YOUR PREFIX]-ml-metadata`.

 
### Installing Kubeflow Pipelines

To install KFP pipelines:
1. Update the `kustomize/kustomization.yaml` with the name the namespace if you want to change the default name.
1. Apply the manifests. From the `kustomize` folder execute the following commands:
```
gcloud container clusters get-credentials  [YOUR CLUSTER NAME] --zone [YOUR ZONE]
kustomize build . | kubectl apply -f -
```

### Creating `user-gcp-sa` secret
Some pipelines - including TFX pipelines - use the pivate key stored in the `user-gcp-sa` secret to access GCP services. Use the same private key you used when configuring Cloud SQL Proxy.
```
kubectl create secret -n [your-namespace] generic user-gcp-sa --from-file=user-gcp-sa.json=application_default_credentials.json
```

## Accessing KFP UI

After the installation completes, you can access the KFP UI from the following URL. You may need to wait a few minutes before the URL is operational.

```
echo "https://"$(kubectl describe configmap inverse-proxy-config -n kubeflow | grep "googleusercontent.com")
```
