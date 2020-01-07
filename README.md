# Production ML workflows on Google Cloud

This repo manages a set of labs designed to demonstrate best practices and patterns for implementing and operationalizing production grade ML workflows on Google Cloud Platform.

With a few exceptions the labs are self-contained - they don't rely on other labs. The goal is to create a portoflio of labs that can be utilized in development and delivery of scenario specific demos and workshops. 

- **Lab-00-Environment-Setup**. This lab guides you through the process of provisioning and configuring a reference MLOps environment on GCP. Most other labs rely on the environment configured in this lab. . 

- **Lab-11-KFP-CAIP**. This lab walks you through the process of authoring and operationalizing the KFP pipeline that utilizes BigQuery and Cloud AI Platform Training and Prediction to train and deploy an **sklearn** model. During the lab you:
    - Analyze the data and develop data processing and training code snippets in Jupyter Lab
    - Refactor the code into KFP components and a KFP pipeline
    - Author the CI/CD workflow to build and deploy the KFP pipeline using **Cloud Build**
    - Integrate the CI/CD workflow with GitHub
    - Integrate the machine learning KFP pipeline with the upstream data management pipeline




