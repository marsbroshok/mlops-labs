# Covertype Data Set

This dataset is based on **Covertype Data Set** from UCI Machine Learning Repository

https://archive.ics.uci.edu/ml/datasets/covertype

The original dataset has been preprocessed to convert the one-hot encoded **Wilderness_Area** and **Soil_Type** variables to text and (categorical) integer, respectively. The original dataset has also been divided into 4 splits: 
- Training - 431012 exmplates
- Validation - 50,000 examples
- Testing - 50,000 examples
- Serving - 50,000 examples

The original dataset is at
gs://workshop-datasets/covertype/orig

The preprocessed datasets are at:
gs://workshop-datasets/covertype/preprocessed/training
gs://workshop-datasets/covertype/preprocessed/validation
gs://workshop-datasets/covertype/preprocessed/testing
gs://workshop-datasets/covertype/preprocessed/serving

