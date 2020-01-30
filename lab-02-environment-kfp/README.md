# Setting up an MLOps environment on GCP.

The labs in this repo are designed to run in a reference MLOps environment. The environment is configured to support effective development and operationalization of production grade ML workflows.

![Reference topolgy](/images/lab_300.png)

The core services in the environment are:
- AI Platform Notebooks - ML experimentation and development
- AI Platform Training - scalable, serverless model training
- AI Platform Prediction - scalable, serverless model serving
- Dataflow - distributed data processing
- BigQuery - analytics data warehouse
- Cloud Storage - unified object storage
- TensorFlow Extended/Kubeflow Pipelines (TFX/KFP) - machine learning pipelines
- Cloud SQL - machine learning metadata  management
- Cloud Build - CI/CD
    

In this lab, you will provision a lightweight deployment of **Kubeflow Pipelines**. 

## Enabling the required cloud services

In addition to the [services enabled by default](https://cloud.google.com/service-usage/docs/enabled-service), the following additional services must be enabled in the project hosting an MLOps environment:

1. Compute Engine
1. Container Registry
1. AI Platform Training and Prediction
1. IAM
1. Dataflow
1. Kubernetes Engine
1. Cloud SQL
1. Cloud SQL Admin
1. Cloud Build
1. Cloud Resource Manager

If you completed `lab-01-environment-notebook` the service are already enabled so you can skip to the next section.

Use [GCP Console](https://console.cloud.google.com/) or `gcloud` command line interface in [Cloud Shell](https://cloud.google.com/shell/docs/) to [enable the required services](https://cloud.google.com/service-usage/docs/enable-disable) . 

To enable the required services using `gcloud`:
1. Start GCP [Cloud Shell](https://cloud.google.com/shell/docs/)

2. Execute the below command.
```
PROJECT_ID=[YOUR_PROJECT_ID]

gcloud config set project $PROJECT_ID

gcloud services enable \
cloudbuild.googleapis.com \
container.googleapis.com \
cloudresourcemanager.googleapis.com \
iam.googleapis.com \
containerregistry.googleapis.com \
containeranalysis.googleapis.com \
ml.googleapis.com \
sqladmin.googleapis.com \
dataflow.googleapis.com \
automl.googleapis.com
```

3. After the services are enabled, [grant the Cloud Build service account the Project Editor role](https://cloud.google.com/cloud-build/docs/securing-builds/set-service-account-permissions).

## Deploying Kubeflow Pipelines 

The below diagram shows an MVP environment for a lightweight deployment of Kubeflow Pipelines on GCP:

![KFP Deployment](/images/kfp.png)

The environment includes:
- A VPC to host GKE cluster
- A GKE cluster to host KFP services
- A Cloud SQL managed MySQL instance to host KFP and ML Metadata databases
- A Cloud Storage bucket to host artifact repository

The KFP services are deployed to the GKE cluster and configured to use the Cloud SQL managed MySQL instance. The KFP services access the Cloud SQL through [Cloud SQL Proxy](https://cloud.google.com/sql/docs/mysql/sql-proxy). External clients use [Inverting Proxy](https://github.com/google/inverting-proxy) to interact with the KFP services.


*The current versions of the labs have been tested with Kubeflow Pipelines 0.1.36. KFP 0.1.37, 0.1.38, 0.1.39 introduced [the issue](https://github.com/kubeflow/pipelines/issues/2764) that causes some labs to fail. After the issue is addressed we will update the setup to utilize the newer version of KFP.*

Provisioning of the environment has been broken into two steps. In the first step you provision and configure core infrastructure services required to host **Kubeflow Pipelines**, including GKE, Cloud SQL and Cloud Storage. In the second step you deploy and configure **Kubeflow Pipelines**.

The provisioning of the infrastructure components  has been automated with [Terraform](https://www.terraform.io/).  The Terraform HCL configurations can be found in the [terraform folder](terraform). The deployment of **Kubeflow Pipelines** is facilitated with [Kustomize](https://kustomize.io/). The Kustomize overlays are in the [kustomize folder](kustomize).

You will run provisioning scripts using **Cloud Shell**. 

**Terraform** is pre-installed in **Cloud Shell**. Before running the scripts you need to install **Kustomize**.

To install **Kustomize** in **Cloud Shell**:
```
cd ~/bin
wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.3.0/kustomize_v3.3.0_linux_amd64.tar.gz
tar xvf kustomize_v3.3.0_linux_amd64.tar.gz
rm kustomize_v3.3.0_linux_amd64.tar.gz
cd
```
The above command installs **Kustomize** to the `bin` folder in your home directory, which by default is on the `PATH`. **Kustomzie** is a single executable. If you don't need it anymore you can delete the file.

### Deploying infrastructure services to host Kubeflow Pipelines


1. Clone this repo under the `home` folder.
```
cd 
git clone https://github.com/jarokaz/mlops-labs.git
cd mlops-labs/lab-02-environment-kfp
```

4. Provision infrastructure:
```
./provision-infra.sh [PROJECT_ID] [REGION] [ZONE] [PREFIX]
```
Where 
- `[PROJECT_ID]` - your project ID
- `[REGION]` - the region for a Cloud SQL instance. We recommend using `us-central1`
- `[ZONE]` - the zone for a GKE cluster. We recommend using `us-central1-a`
- `[PREFIX]` - the name prefix that will be added to the names of provisioned resources
4. Review the logs generated by the script for any errors.

### Installing Kubeflow Pipelines components
```
./deploy-kfp.sh  [PROJECT_ID] [NAMESPACE] [SQL_PASSWORD]
```
Where:
- `[PROJECT_ID]` - your project ID
- `[NAMESPACE]` - the namespace to host KFP components
- `[SQL_PASSWORD]` - the password for the Cloud SQL `root` user

*Note: The `deploy-kfp.sh` script does not allow you to specify a SQL username. The reason is that in the 0.1.36 versions of KFP the SQL username must be `root`*.

## Accessing KFP UI

After the installation completes, you can access the KFP UI from the following URL. You may need to wait a few minutes before the URL is operational.

```
echo "https://"$(kubectl describe configmap inverse-proxy-config -n [NAMESPACE] | grep "googleusercontent.com")
```
