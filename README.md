# Production ML workflows on Google Cloud

This repo manages a set of labs designed to demonstrate best practices and patterns for implementing and operationalizing production grade ML workflows on Google Cloud Platform. The goal is to create a portoflio of labs that can be utilized in development and delivery of scenario specific demos and workshops. 

- **Series 0x labs**. These lab guides you through the process of provisioning and configuring a reference MLOps environment on GCP. Most other labs rely on the environment configured in the labs. The **lab-01** lab walks you through the process of creating an **AI Platform Notebooks** instance based on a custom container image optimized for KFP/TFX development. In the **lab-02** lab, you provision a lightweight deployment of **Kubeflow Pipelines**. 

- **Series 1x labs**. These lab walks you through the process of authoring and operationalizing the KFP pipelines that utilize GCP managed services to train and deploy machine learning models. During the labs you will:
    - **lab-11** - Develop a custom container image for **AI Platform Training**
    - **lab-12** - Create, deploy, and run a KFP pipeline that utilizes **AI Platform** for training and model deployment
    - **lab-13** - Author the CI/CD workflow to build and deploy the KFP pipeline using **Cloud Build**
    - **lab-14** - Create, deploy, and run a KFP pipeline that utilized **AutoML Tables** for training and model deployment
    
- **Series 2x labs**. These labs teach you how to develop and operationalize **Tensorflow Extended (TFX)** pipelines

- **Series 3x labs**. In these labs, you deep-dive into **TensorFlow Data Validation**, **TensorFlow Transform**, and **TensorFlow Model Analysis** libraries.




