# Provisioning a lightweight deployment of Kubeflow Pipelines

This lab  describes the steps to provision a lighweight deployment of  Kubeflow Pipelines.

The accompanying lab -  `lab-01-env-setup-ai-notebook` - walks you through the steps required to provision  an AI Platfom Notebooks instance configured based on a custom container image optimized for TFX/KFP development.

## Enabling the required cloud services

If you walked through `lab-01-env-setup-ai-notebook`, you can skip this step as the required services have been already enabled.

In addition to the [services enabled by default](https://cloud.google.com/service-usage/docs/enabled-service), the following additional services must be enabled in the project hosting the MLOps environment:

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

Use [GCP Console](https://console.cloud.google.com/) or `gcloud` command line interface in [Cloud Shell](https://cloud.google.com/shell/docs/) to [enable the required services](https://cloud.google.com/service-usage/docs/enable-disable) . 

To enable the required services using `gcloud`:
1. Start GCP [Cloud Shell](https://cloud.google.com/shell/docs/)
2. Make sure that **Cloud Shell** is configured to use your project
```
PROJECT_ID=[YOUR_PROJECT_ID]

gcloud config set project $PROJECT_ID
```

3. Enable services
```
gcloud services enable \
cloudbuild.googleapis.com \
container.googleapis.com \
cloudresourcemanager.googleapis.com \
iam.googleapis.com \
containerregistry.googleapis.com \
containeranalysis.googleapis.com \
ml.googleapis.com \
sqladmin.googleapis.com \
dataflow.googleapis.com 
```

3. After the services are enabled, grant the Cloud Build service account the Project Editor role.
```
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
CLOUD_BUILD_SERVICE_ACCOUNT="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$CLOUD_BUILD_SERVICE_ACCOUNT \
  --role roles/editor
```


## Creating Kubeflow Pipelines environment

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
cd /usr/local//bin
sudo wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.3.0/kustomize_v3.3.0_linux_amd64.tar.gz
sudo tar xvf kustomize_v3.3.0_linux_amd64.tar.gz
sudo rm kustomize_v3.3.0_linux_amd64.tar.gz
cd
```
The above command installs **Kustomize** to the `/usr/local/bin` folder, which by default is on the `PATH`. **Kustomize** is a single executable. Note that this folder will be reset after you disconnect from **Cloud Shell**. 

### Provisioning infrastructure to host Kubeflow Pipelines

The 

1. Clone this repo under the `home` folder.
```
cd 
git clone https://github.com/jarokaz/mlops-labs.git
cd mlops-labs/lab-02-environment-kfp
```

2. Review the `provision-infra.sh` installation script

3. Run the installation script
```
./provision-infra.sh [PROJECT_ID] [PREFIX] [REGION] [ZONE] 
```
Where 

|Parameter|Optional|Description|
|-------------|---------|-------------------------------|
|[PROJECT_ID]| Required|The project id of your project.|
|[PREFIX]|Optional|A name prefix tha will be added to the names of provisioned resources. If not provided [PROJECT_ID] will be used as the prefix|
|[REGION]|Optional|The region for the Cloud SQL instance.  If not provided the `us-central1` region will be used|
|[ZONE]|Optional|The zone for the GKE cluster.If not provided the `us-central1-a` will be used.|

We recommend using the defaults for the region and the zone.

4. Review the logs generated by the script for any errors.

### Deploying Kubeflow Pipelines 

1. Review the `deploy-kfp.sh` deployment script
2. Run the deployment script

```
./deploy-kfp.sh  [PROJECT_ID] [SQL_PASSWORD] [NAMESPACE] 
```
Where:

|Parameter|Optional|Description|
|-------------|---------|-------------------------------|
|[PROJECT_ID]| Required|The project id of your project.|
|[SQL_PASSWORD]|Required|The password for the Cloud SQL `root` user. In 0.1.36 version of KFP the SQL username must be `root`|
|[NAMESPACE]|Optional|The namespace to deploy KFP to. If not provided the `kubeflow` namespace will be used




## Accessing KFP UI

After the installation completes, you can access the KFP UI from the following URL. You may need to wait a few minutes before the URL is operational.

```
echo "https://"$(kubectl describe configmap inverse-proxy-config -n [NAMESPACE] | grep "googleusercontent.com")
```
