# Setting up an MLOps environment on GCP.

The labs in this repo are designed to run in the reference MLOps environment. The environment is configured to support effective development and operationalization of production grade ML workflows.

![Reference topolgy](/images/lab_300.png)

The core services in the environment are:
- ML experimentation and development - AI Platform Notebooks 
- Scalable, serverless model training - AI Platform Training  
- Scalable, serverless model serving - AI Platform Prediction 
- Distributed data processing - Dataflow  
- Analytics data warehouse BigQuery 
- Artifact store - Google Cloud Storage 
- Machine learning pipelines - TensorFlow Extended (TFX) and Kubeflow Pipelines (KFP)
- Machine learning metadata  management - Cloud SQL
- CI/CD tooling - Cloud Build
    
In the reference lab environment, all services are provisioned in the same [Google Cloud Project](https://cloud.google.com/storage/docs/projects). 

The below diagram shows the architeacture of a lightweight deployment of Kubeflow Pipelines on GKE:

![KFP Deployment](/images/kfp.png)

The deployment includes:
- A VPC to host GKE cluster
- A GKE cluster to host KFP services
- A Cloud SQL managed MySQL instance to host KFP and ML Metadata databases
- A Cloud Storage bucket to host artifact repository

The KFP services are deployed to the GKE cluster and configured to use the Cloud SQL managed MySQL instance. The KFP services access the Cloud SQL through [Cloud SQL Proxy](https://cloud.google.com/sql/docs/mysql/sql-proxy). External clients use [Inverting Proxy](https://github.com/google/inverting-proxy) to interact with the KFP services.

*The current versions of the labs have been tested with Kubeflow Pipelines 0.1.36. KFP 0.1.37, 0.1.38, 0.1.39 introduced [the issue](https://github.com/kubeflow/pipelines/issues/2764) that causes some labs to fail. After the issue is addressed we will update the setup to utilize the newer version of KFP.*

## Provisioning the lab environment

Provisioning of the environment has been fully automated with the `./install.sh` script. The script uses **Terraform** to provision and configure the required cloud services and **Kustomize** to configure and deploy Kubeflow Pipelines.

The script goes through the following steps:
1. Enables the required GCP cloud services
1. Assigns the Cloud Build service account the the project editor role
1. Builds the custom container optimized for TFX/KFP development to be used with AI Platform Notebooks
1. Provisions an instance of AI Platform Notebooks based on the custom container image
1. Creates and configures two service accounts:
    - A service account for GKE worker nodes
    - A service account to be used by KFP pipelines
1. Creates a VPC to host a GKE cluster
1. Creates a GKE cluster
1. Creates a Cloud SQL instance 
1. Creates a GCS bucket 
1. Deploys Kubeflow Pipelines and configures the KFP services to use Cloud SQL for ML metadata management and GCS for artifact storage

### Running the installation script

You will run the provisioning script using **Cloud Shell**. 

**Terraform** is pre-installed in **Cloud Shell**. The current version of `kubectl` installed by default in **Cloud Shell** does not support **Kustomize**. *When the default version of `kubectl` in **Cloud Shell** is upgraded to the version that supports **Kustomize** the below step will not be necessary and will be removed*.

To install **Kustomize** in **Cloud Shell**:
```
cd /usr/local//bin
sudo wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.3.0/kustomize_v3.3.0_linux_amd64.tar.gz
sudo tar xvf kustomize_v3.3.0_linux_amd64.tar.gz
sudo rm kustomize_v3.3.0_linux_amd64.tar.gz
cd
```
The above command installs **Kustomize** to the `/usr/local/bin` folder, which by default is on the `PATH`. **Kustomize** is a single executable. Note that this folder will be reset - and Kustomize removed - after you disconnect from **Cloud Shell**.


To start the provisioning script:

1. Open **Cloud Shell**
2. Clone this repo under the `home` folder.
```
cd /
git clone https://github.com/jarokaz/mlops-labs.git
cd mlops-labs/lab-00-environment-setup
```

3. Start installation
```
./install.sh $PROJECT_ID 
```
By default, the script uses the [PROJECT_ID]-[RESOURCE-NAME] format to name the provisioned resources. For example, if your project's ID was `mlops-workshop` the script would provision the resources with the following names:
- `mlops-workshop-notebook` - The AI Platform Notebook instance
- `mlops-workshop-cluster` - The GKE cluster to host KFP services
- `mlops-workshop-artifact-store` - The GCS bucket for artifact storage.
- `mlops-workshop-metadata` - The Cloud SQL instances

If you want to use a different prefix than the project ID, provide it as the second parameter to the `install.sh` script.

By default, all regional resources are provisioned in the `us-central1` region and all zonal  are provisioned in the `us-central1-a` zone. Although not recommened, you can use another region or zone by providing their names as the third and fourth parameters to the `install.sh` script.

By default, the KFP services are deployed into the `kubeflow` namespace on the GKE cluster. If you want to change it provide the name of your namespace as the fifth parameter to the `install.sh` script.


4. Review the logs generated by the script for any errors.

## Accessing KFP UI

After the installation completes, you can access the KFP UI from the following URL. You may need to wait a few minutes before the URL is operational.

```
gcloud container clusters get-credentials $PREFIX-cluster --zone $ZONE
echo "https://"$(kubectl describe configmap inverse-proxy-config -n kubeflow | \
grep "googleusercontent.com")
```
