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
    
In the reference environment, all services are provisioned in the same [Google Cloud Project](https://cloud.google.com/storage/docs/projects). Before proceeding make sure that your account has access to the project and is assigned to the **Owner** or **Editor** role.

## Copy the installation files to Cloud Shell
Although you can run the installation from any workstation configured with *Google Cloud SDK* and *Terraform*, the following instructions have been based on and tested with [Cloud Shell](https://cloud.google.com/shell/).

In the home directory of your **Cloud Shell**, replicate the folder structure of this lab. If you prefer, you can clone the whole repo using `git clone` command:
```
git clone https://github.com/jarokaz/mlops-labs.git
```


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

Use [GCP Console](https://console.cloud.google.com/) or `gcloud` command line interface in [Cloud Shell](https://cloud.google.com/shell/docs/) to [enable the required services](https://cloud.google.com/service-usage/docs/enable-disable) . 

You can use the `enable_apis.sh` script to enable the required services from **Cloud Shell**.
```
./enable.sh
```

*Make sure that the Cloud Build service account (that was created when you enabled the Cloud Build service) is granted the Kubernetes Engine Developer role.*



## Provisioning an AI Platform Notebook instance
You will use an **AI Platform Notebooks** instance as your primary experimentation/development workspace. Different labs use a different configuration of **AI Platform Notebooks** so make sure to check the lab's README file before starting.

The **AI Platform Notebooks** instances used in the labs are based on custom container images have all components required for a given lab pre-installed.

The process of creating a custom container image has been automated with  [Cloud Build](https://cloud.google.com/cloud-build/). To build the image and push it to your project's **Container Registry** use **Cloud Shell** to run the `build.sh` script from the `notebook-images/[IMAGE_TYPE]` folder. Make sure to check the given lab's README for the required IMAGE_TYPE.

```
cd notebook-images/[IMAGE_TYPE]
gcloud config set project [YOUR_PROJECT_ID]
./build.sh
```

After the build completes, follow the  [instructions in AI Platform Notebooks Documentation](https://cloud.google.com/ai-platform/notebooks/docs/custom-container) to create an **AI Platform Notebook** instance. In the **Docker container image** field, enter the following image name: `gcr.io/[YOUR_PROJECT_NAME/[IMAGE_TYPE]`.



## Deploying Kubeflow Pipelines 

The below diagrame shows an MVP infrastructure for a lightweight deployment of Kubeflow Pipelines on GCP:

![KFP Deployment](/images/kfp.png)

The environment includes:
- A VPC to host GKE cluster
- A GKE cluster to host KFP services
- A Cloud SQL managed MySQL instance to host KFP and ML Metadata databases
- A Cloud Storage bucket to host artifact repository

The KFP services are deployed to the GKE cluster and configured to use the Cloud SQL managed MySQL instance. The KFP services access the Cloud SQL through [Cloud SQL Proxy](https://cloud.google.com/sql/docs/mysql/sql-proxy). External clients use [Inverting Proxy](https://github.com/google/inverting-proxy) to interact with the KFP services.


The provisioning of the infrastructure components and installation of Kubeflow Pipelines has been automated with Terraform and Kustomize. The Terraform HCL configurations can be found in the `kfp/terraform` folder. The Kustomize overlays are in the `kfp/kustomize` folder.

To deploy Kubeflow Pipelines:

1. Open **Cloud Shell**
2. Install **Kustomize** 
```
cd /usr/local/bin 
sudo wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.3.0/kustomize_v3.3.0_linux_amd64.tar.gz 
sudo tar xvf kustomize_v3.3.0_linux_amd64.tar.gz
sudo rm kustomize_v3.3.0_linux_amd64.tar.gz
```
3. Start installation by executing the `install.sh` script from the `/Lab-00-EnvironmentSetup` folder.
```
./install.sh [PROJECT_ID] [REGION] [ZONE] [PREFIX] [NAMESPACE] [SQL_USERNAME] [SQL_PASSWORD]
```
Where:
- `[PROJECT_ID]` - your project ID
- `[REGION]` - the region for a Cloud SQL instance
- `[ZONE]` - the zone for a GKE cluster
- `[PREFIX]` - the name prefix that will be added to the names of provisioned resources
- `[SQL_USERNAME]` - the Cloud SQL user that will be used by KFP services to acces the Cloud SQL instance
- `[SQL_PASSWORD]` - the password of the Cloud SQL user



## Accessing KFP UI

After the installation completes, you can access the KFP UI from the following URL. You may need to wait a few minutes before the URL is operational.

```
echo "https://"$(kubectl describe configmap inverse-proxy-config -n kubeflow | grep "googleusercontent.com")
```

# Optional 
## Step by step instructions for installing Kubeflow Pipelines
If you need to understand in more detail the process of installing a lightweight deployment of Kubeflow Pipelines the following instructions step through the same process as automated by the `install.sh` script.

*Before procedding make sure to enable the required Cloud Services as described in the previous section*.

The following instructions have been tested with **Cloud Shell**.

This installation requires **Terraform** and **Kustomize**. **Terraform** is pre-installed in **Cloud Shell**. To install **Kustomize** in **Cloud Shell**:
```
cd /usr/local/bin 
sudo wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.3.0/kustomize_v3.3.0_linux_amd64.tar.gz 
sudo tar xvf kustomize_v3.3.0_linux_amd64.tar.gz
sudo rm kustomize_v3.3.0_linux_amd64.tar.gz
```


### Provisioning infrastructure
The `terraform` folder contains Terraform configuration language scripts that provision an MVP infrastructure required to run a lightweigth deployment of Kubeflow Pipelines.

The `main.tf` file utilizes re-usable Terraform modules from https://github.com/jarokaz/terraform-gcp-kfp, specifically:
- The `modules/service_account` module that creates a GCP service account and grants to the account a set of IAM roles.
- The `modules/vpc` module that creates a VPC network
- The `modules/gke` module that creates a GKE cluster with a default node pool

The `main.tf` script creates:
- A service account to be used by GKE nodes
- A service account to be used by KFP pipelines
- A regional VPC to host a GKE cluster
- A simple GKE cluster with a single (default) node pool
- An instance of Cloud SQL hosted MySQL. For the security reasons, the created instance does not have any use accounts
- A GCS storage bucket

To apply the Terraform configurations:
1. Start **Cloud Shell**.
2. Verify that your GCP project is configured properly
```
gcloud config set project [YOUR_PROJECT_ID]
```
3. If you did not do it in the previous steps replicate the folder structure of this lab in your home directory or clone the whole repository
```
git clone https://github.com/jarokaz/mlops-labs.git
```
4. Navigate to the `terraform folder` in *Lab-00*.
```
cd mlops-labs/Lab-00-Environment-Setup/kfp/terraform
```
5. Initialize Terraform. This downloads Terraform modules used by the script, including the *Google Terraform Provider* and the modules from `jarokaz/terraform-gcp`, and initializes local Terraform state.
```
terraform init
```
6. Apply the configuration. Refer to the previous section for more detail about the variables passed to the apply command. 
```
terraform apply \
-var "project_id=[YOUR_PROJECT_ID]" \
-var "region=[YOUR_REGION]" \
-var "zone=[YOUR_ZONE]" \
-var "name_prefix=[YOUR_NAME_PREFIX]"
```
7. Review the resource configurations that will be provisioned and type `yes` to start provisioning.
8. After the process completes you can review the status of the infrastructure by
```
terraform show
```
### Deploying Kubeflow Pipelines
In this section you deploy Kubeflow Pipelines to your GKE cluster. The KFP services are configured to use the Cloud SQL and the GCS bucket provisioned in the previous step to host metadata databases and an artifacts store.

#### Creating a Kubernetes namespace
The KFP services are installed to a dedicated Kubernetes namespace. You can use any name for the namespace, e.g. *kubeflow*.

1. Get credentials to your cluster:
```
CLUSTER_NAME=$(terraform output cluster_name)
gcloud container clusters get-credentials $CLUSTER_NAME --zone [YOUR_ZONE] --project [YOUR_PROJECT_ID]
```
2. Create a namespace
```
NAMESPACE=[YOUR_NAMESPACE]
kubectl create namespace $NAMESPACE
```

#### Creating `user-gcp-sa` secret
It is recommended to run KFP pipelines using a dedicated service account. A lot of samples, including samples in this repo, assume that the credentials for the service account are stored in a Kubernetes secret named `user-gcp-sa`, under the `application_default_credentials.json` key.

1. Create a private key for the KFP service account created by Terraform in the previous step
```
KFP_SA_EMAIL=$(terraform output kfp_sa_email)
gcloud iam service-accounts keys create application_default_credentials.json --iam-account=$KFP_SA_EMAIL
```
2. Create a Kubernetes secret in your namespace
```
kubectl create secret -n $NAMESPACE generic user-gcp-sa --from-file=application_default_credentials.json --from-file=user-gcp-sa.json=application_default_credentials.json
```
3. Remove the private key
```
rm application_default_credentials.json
```
4. You can verify that the secret stores the private key by executing
```
kubectl get secret user-gcp-sa -n kubeflow -o yaml
```

#### Creating Cloud SQL database user and a Kubernetes secret to hold the user's credentials
The instance of MySQL created by Terraform in the previous step does not have any database users configured. In this step, you create a database user that will be used by KFP and ML Metadata services to access the instance. The services are configured to retrieve the database user credentials from the Kubernetes secret named `mysql-credential`. You can use any name for the database user. Since some older TFX samples assume the user named `root`, it is recommended to use this name if you intend to use the samples from the TFX site. The labs in this repo do not hard code any user names. 

1. Create a database user
```
SQL_INSTANCE_NAME=$(terraform output sql_name)
gcloud sql users create [YOUR_USER_NAME] --instance=$SQL_INSTANCE_NAME --password=[YOUR_PASSWORD] --project [YOUR_PROJECT_ID]
```
2. Create the `mysql-credential` secret to store user name and password
```
kubectl create secret -n $NAMESPACE generic mysql-credential --from-literal=username=[YOUR_USERNAME] --from-literal=password=[YOUR_PASSWORD]
```
3. You can verify that the secret was created in you namespace by executing:
```
kubectl get secret mysql-credential -n $NAMESPACE -o yaml
```
#### Deploying Kubeflow Pipelines using Kustomize
In this step you deploy Kubeflow Pipelines using **Kustomize**.

The Kustomize overlays and patches, which can be found in the `kfp/kustomize` folder, are applied on top of the Kustomize configuration from the Kubeflow Pipelines github repo. 
https://github.com/kubeflow/pipelines/tree/master/manifests/kustomize/env/gcp

The `kustomization.yaml` file in the `kfp/kustomize` folder refers to the 0.1.36 release of KFP as a base. This is the release against which the labs in this repo were tested. As the labs and KFP evolve, this will be updated to align with the required version of KFP.

The `gcp-configurations-patch.yaml` file contains patches that configure the KFP services to retrieve credentials from the secrets created in the previous steps and connection information to the Cloud SQL and the GCS bucket from the Kubernetes **ConfigMap** named `gcp-configs`.

The `gcp-configs` config map is created by **Kustomize** using *configMapGenerator* defined in the `kustomization.yaml` file. The generator is configured to retrieve connections settings from the `gcp-configs.env` environment file.


1. Retrieve connections settings from the Terraform state
```
SQL_CONNECTION_NAME=$(terraform output sql_connection_name)
BUCKET_NAME=$(terraform output artifact_store_bucket)
```
2. Assuming that you are still in the `terraform` folder, navigate to the `kustomize` folder
```
cd ../kustomize
```
3. Create an environment file with connection settings
```
cat > gcp-configs.env << EOF
sql_connection_name=$SQL_CONNECTION_NAME
bucket_name=$BUCKET_NAME
EOF
```
4. Deploy KFP to the cluster
```
kustomize build . | kubectl apply -f -
```
5. To list the workloads comprising Kubeflow Pipelines:
```
kubectl get all -n $NAMESPACE
```


### Accessing KFP UI

After the installation completes, you can access the KFP UI from the following URL. You may need to wait a few minutes before the URL is operational.

```
echo "https://"$(kubectl describe configmap inverse-proxy-config -n kubeflow | grep "googleusercontent.com")
```

## Using the TFX/KFP development image with Visual Studio Code

In the first section of the setup you created a custom container image to use with **AI Platform Notebooks**. 

You can also use this image with Visual Studio Code for both local and remote development.  The following instructions were tested on MacOS but should be transferable to other platforms.

### Preparing your MacOS workstation
1. Install and initialize [Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstart-macos)

1. [Install Docker Desktop for Mac](https://docs.docker.com/docker-for-mac/install/)

1. [Install Visual Studio Code](https://code.visualstudio.com/download)

1. [Install Visual Studio Code Remote Development Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)


### Configuring Visual Studio Code for local development
1. Clone this repo on your workstation
2. In the repo's root create the `.devcontainer` folder.
3. In the `.devcontainer` folder create a Dockerfile using the following template. Make sure to replace the `[YOUR_PROJECT_NAME]` placeholder with you project id.
```
FROM gcr.io/[YOUR_PROJECT_NAME/tfx-kfp-dev:latest
```
4. In the `.devcontainer` folder create the `devcontainer.json` file. Refer to https://github.com/microsoft/vscode-dev-containers/tree/master/containers/docker-existing-dockerfile for more information about the configuration options. The below configuration tells VSC to create an image using the provided Dockerfile and install Microsoft Python extension after the container is started.
```
{
	"name": "Existing Dockerfile",
	"context": "..",
	"dockerFile": "Dockerfile",
	"settings": { 
		"terminal.integrated.shell.linux": null
	},
	"extensions": ["ms-python.python"]
}
```
5. From the Visual Studio Code command pallete (**[SHIFT][COMMAND][P]**) select **Remote-Containers:Open Folder in Container**. Find the root folder of the repo. After selecting the folder, Visual Studio Code downloads your image, starts the container and installs the Python extension to the container. 

### Configuring Visual Studio Code for remote development
1. Create an AI Platform Notebook using the development image as described in the **Creating an AI Platform Notebook** section.
2. Make sure you can connect to the AI Platform Notebook's vm instance from your workstation using `ssh`
```
gcloud compute ssh [YOUR AI PLATFORM NOTEBOOK VM NAME] --zone [YOUR ZONE]
```
2. Create a configuration for the VM in your `~/.ssh/config`
```
Host [YOUR CONFIGURATION NAME]
  User [YOUR USER NAME]
  HostName [YOUR VM'S IP ADDRESS]
  IdentityFile /Users/[YOUR USER NAME]/.ssh/google_compute_engine
```
3. Test the configuration
```
ssh [YOUR CONFIGURATION NAME]
```
4. You can now connect to AI Platform Notebook using a SSH tunnel. 
  - Update the `docker.host` property in your user or workspace Visual Studio Code `settings.json` as follows
  ```
  "docker.host":"tcp//localhost:23750"
  ```
  - From a local terminal set up an SSH tunnel
  ```
  ssh -NL localhost:23750:/var/run/docker.sock [YOUR CONFIGURATION NAME] 
  ```

5. In Visual Studio Code bring up the **Command Palette** (**[SHIFT][COMMAND][P]**)) and type in **Remote-Containers** for a full list of commands. Choose **Attach to Running Container** and select your ssh configuration.


