# Covertype Data Set

This dataset is based on **Covertype Data Set** from UCI Machine Learning Repository

https://archive.ics.uci.edu/ml/datasets/covertype

The original dataset has been modified in the following ways:

- Columns 10-13 that a are one-hot encoded representation of the wilderness area designation have been replaced by a single column with a name of the Wilderness Area:
    - Rawah - Rawah Wilderness Area
    - Neota - Neota Wilderness Area
    - Comanche - Comanche Peak Wilderness Area
    - Cache - Cache la 
    - 
- Columns 14-53 that are a one-hot encoded representation of the soil type designation have been replaced by a single column with the ELU code of the soil type.



The modified dataset has been divided into 5 splits: 
- Training - 431012 exmplates
- Training-anomaly
- Evaluation -  75,000 examples
- Serving - 75,000 examples

The *Testing-corry


The original dataset is at
gs://workshop-datasets/covertype/orig

The modified datasets are at:
gs://workshop-datasets/covertype/preprocessed/training
gs://workshop-datasets/covertype/preprocessed/validation
gs://workshop-datasets/covertype/preprocessed/testing
gs://workshop-datasets/covertype/preprocessed/serving

