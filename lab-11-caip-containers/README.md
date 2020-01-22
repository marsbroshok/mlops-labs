# Using custom containers with AI Platform Training

Containers on AI Platform is a feature that allows you to run your training application as a docker container. 

In this lab, you will develop, package as a docker image, and run on **AI Platform Training** a training application that builds an  **scikit-learn** model.


## Lab scenario

Using the [Covertype Data Set](../datasets/covertype/README.md) you will develop a multi-class classification model that predicts the type of forest cover from cartographic data. 

You will work in a Jupyter notebook to analyze data, create training, validation, and testing data splits, develop a training script, package the script as a docker image, and submit and monitor an **AI Platform Training** job. In the later labs of this lab series, you will operationalize this manual workflow using **Kubeflow Pipelines**.


## Lab setup

### AI Platform Notebook configuration
You will use the **AI Platform Notebooks** instance created in **lab-01-environment-notebook**. For this lab you don't need the KFP environment.


### Lab dataset
This lab uses the [Covertype Dat Set](../datasets/covertype/README.md). The lab's notebook is designed to retrieve the data from BigQuery. Before proceeding with the lab, upload the dataset to BigQuery from GCS:

1. Open new terminal in you **JupyterLab**

2. Create the BigQuery dataset and upload the `covertype.csv` file. 
```
PROJECT_ID=[YOUR_PROJECT_ID]
DATASET_LOCATION=US
DATASET_ID=lab_11
TABLE_ID=covertype
DATA_SOURCE=gs://workshop-datasets/covertype/full/covertype.csv
SCHEMA=Elevation:INTEGER,\
Aspect:INTEGER,\
Slope:INTEGER,\
Horizontal_Distance_To_Hydrology:INTEGER,\
Vertical_Distance_To_Hydrology:INTEGER,\
Horizontal_Distance_To_Roadways:INTEGER,\
Hillshade_9am:INTEGER,\
Hillshade_Noon:INTEGER,\
Hillshade_3pm:INTEGER,\
Horizontal_Distance_To_Fire_Points:INTEGER,\
Wilderness_Area:STRING,\
Soil_Type:INTEGER,\
Cover_Type:INTEGER

bq --location=$DATASET_LOCATION --project_id=$PROJECT_ID mk --dataset $DATASET_ID

bq --project_id=$PROJECT_ID --dataset_id=$DATASET_ID load \
--source_format=CSV \
--skip_leading_rows=1 \
--replace \
$TABLE_ID \
$DATA_SOURCE \
$SCHEMA
```

