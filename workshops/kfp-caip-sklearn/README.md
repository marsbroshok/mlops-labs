# Continuous training with scikit-learn and Cloud AI Platform

The hands-on labs in this series guide you through the process of implementing a continuous training pipeline that automates training and deployment of a **scikit-learn** model. The pipeline orchestrates GCP managed services:
- BigQuery to prepare training, evaluation, and testing data splits, 
- AI Platform Training train a scikit-learn model, and
- AI Platform Prediction as the model deployment target

The below diagram represents the workflow orchestrated by the pipeline.

![Training pipeline](/images/kfp-caip.png).



