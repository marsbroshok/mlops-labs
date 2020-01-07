# Analyzing and validating data with TensorFlow Data Validation.

In this lab, you will learn how to use TensorFlow Data Validation (TFDV) for structured data analysis and validation:
- Generating descriptive statistics, 
- Inferring and fine tuning schema, 
- Checking for and fixing data anomalies,
- Detecting drift and skew. 


## Lab Setup
### AI Platform Notebook configuration
You will use the **AI Platform Notebooks** instance configured with a custom container image. To prepare the **AI Platform Notebooks** instance:

1. In **Cloud Shell**, navigate to the `lab-00-environment-setup/notebook-images/tf20-tfx015` folder.
2. Build the container image
```
./build.sh
```
3. Provision the **AI Platform Notebook** instance based on a custom container image, following the  [instructions in AI Platform Notebooks Documentation](https://cloud.google.com/ai-platform/notebooks/docs/custom-container). In the **Docker container image** field, enter the following image name: `gcr.io/[YOUR_PROJECT_ID]/tfx-dev:TF20-TFX015`.

### Lab dataset
This lab uses the [Covertype Dat Set](../datasets/covertype/README.md). 

### GCS staging bucket

Create the GCS bucket that will be used as a staging area during the lab.
```
PROJECT_ID=[YOUR_PROJECT_ID]
BUCKET_NAME=gs://${PROJECT_ID}-lab-21
gsutil mb -p $PROJECT_ID $BUCKET_NAME
```

## Lab Exercises
Follow the instructor, who will walk you throught the `tfdv-covertype.ipynb` notebook.

