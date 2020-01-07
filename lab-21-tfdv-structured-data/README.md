# Analyzing data with TensorFlow Data Validation.

01-Covertype-Dataset - Analysis using Covertype-Dataset

## Lab setup
AI Platform Notebook configuration
You will use the AI Platform Notebooks instance configured with a custom container image. To prepare the AI Platform Notebooks instance:

In Cloud Shell, navigate to the `Lab-00-Environment-Setup/notebook-images/tf20-tfx015` folder.
Build the container image
./build.sh
Provision the AI Platform Notebook instance based on a custom container image, following the instructions in AI Platform Notebooks Documentation. In the Docker container image field, enter the following image name: `gcr.io/[YOUR_PROJECT_NAME/tfx-dev:TF20-TFX015`.
