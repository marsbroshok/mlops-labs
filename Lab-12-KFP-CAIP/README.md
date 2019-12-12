# Orchestraiting model training and deployment with KFP and Cloud AI Platform

## Lab setup

### AI Platform Notebook configuration
In this lab you use the **AI Platform Notebooks** instance configured with the `tf115-tfx015-kfp137` image. To prepare the lab:
1. Create/use the **AI Platform Notebook** instance using the process described in [Lab-00-Environment-Setup](../Lab-00-Environment-Setup/README.md).
2. Open **JupyterLab** in your instance


### Lab dataset
This lab uses the [Covertype Dat Set](../datasets/covertype/README.md). The pipeline developed in the lab sources the dataset from BigQuery. Before proceeding with the lab upload the dataset to BigQuery:

1. Open new terminal in you **JupyterLab**
2. Clone this repo in the `home` folder
```
cd /home
git clone https://github.com/jarokaz/mlops-labs.git
```

3. Navigate to the datasets folder and upload the dataset to BigQuery
```
cd mlops-lab/datasets/covertype

PROJECT_ID=[YOUR_PROJECT_ID]
DATASET_LOCATION=US
DATASET_ID=lab_12
TABLE_ID=covertype
DATA_SOURCE=covertype.csv
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

### AI Platform job dir bucket
```
BUCKET_NAME=gs://lab_12_bucket
gsutil mb -p $PROJECT_ID $BUCKET_NAME
```

