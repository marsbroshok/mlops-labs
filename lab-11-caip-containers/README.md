# Using custom containers with AI Platform Training

Containers on AI Platform is a feature that allows you to run your training application as a docker container. 

In this lab, you will develop, package as a docker image, and run on **AI Platform Training** a training application that builds an  **scikit-learn** model.


## Lab Scenario

Using the [Covertype Data Set](../datasets/covertype/README.md) you will develop a multi-class classification model that predicts the type of forest cover from cartographic data. 

You will work in a Jupyter notebook to analyze data, create training, validation, and testing data splits, develop a training script, package the script as a docker image, and submit and monitor an **AI Platform Training** job. In the later labs of this lab series, you will operationalize this manual workflow using **Kubeflow Pipelines**.


## Lab Setup

### AI Platform Notebook configuration
You will use the **AI Platform Notebooks** instance created in **lab-01-environment-notebook**. For this lab you don't need the KFP environment.


## Lab Exercises

Follow the instructor who will guide you through the `covertype_experimentation.ipynb` notebook.
