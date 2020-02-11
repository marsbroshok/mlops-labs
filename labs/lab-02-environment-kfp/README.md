# Setting up an MLOps environment on GCP - Part 2 - Provisioning a lightweight deployment of Kubeflow Pipelines

The labs in this repo are designed to run in the reference MLOps environment. The environment is configured to support effective development and operationalization of production grade ML workflows.

![Reference topolgy](/images/lab_300.png)

The core services in the environment are:
- ML experimentation and development - AI Platform Notebooks 
- Scalable, serverless model training - AI Platform Training  
- Scalable, serverless model serving - AI Platform Prediction 
- Distributed data processing - Dataflow  
- Analytics data warehouse - BigQuery 
- Artifact store - Google Cloud Storage 
- Machine learning pipelines - TensorFlow Extended (TFX) and Kubeflow Pipelines (KFP)
- Machine learning metadata  management - ML Metadata on Cloud SQL
- CI/CD tooling - Cloud Build
    
In the reference lab environment, all services are provisioned in the same [Google Cloud Project](https://cloud.google.com/storage/docs/projects). 

The provisioning of the environment has been fully automated as described in `lab-00-environment-setup`.  

As an alternative to a fully automated setup, `lab-01-environment-notebook` and `lab-02-environment-kfp` describe the semi-manual process to individually provision components of the environment.

This lab - `lab-02-environment-kfp` - describe the steps to provision Cloud SQL, GKE and GCS and deploying Kubeflow Pipelines

The accompanying lab -  `lab-01-environment-notebook` - walks you through the steps required to provision  an AI Platfom Notebooks instance configured based on a custom container image optimized for TFX/KFP development.


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
