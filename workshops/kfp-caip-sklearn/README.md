# Continuous training with scikit-learn and Cloud AI Platform

The hands-on labs in this series guide you through the process of implementing a continuous training pipeline that automates training and deployment of a **scikit-learn** model. 

The below diagram represents the workflow orchestrated by the pipeline.

![Training pipeline](/images/kfp-caip.png).

1. The source data is in BigQuery
2. BigQuery is used to prepare training, evaluation, and testing data splits, 
3. AI Platform Training is used to tune hyperparameters and train a scikit-learn model, and
4. The model's performance is validated against a configurable performance threshold
4. If the model meets or exceeds the performance requirements it is deployed as an online service using AI Platform Prediction



