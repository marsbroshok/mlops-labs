# Covertype Data Set

This dataset is based on **Covertype Data Set** from UCI Machine Learning Repository

https://archive.ics.uci.edu/ml/datasets/covertype

The original dataset has been modified in the following ways:

- Columns 10-13 that in the original dataset are a one-hot encoded representation of the wilderness area designation have been replaced by a single column with a name of the Wilderness Area, using the following mappings:

Code | Wilderness Area 
----------------|-----
Rawah | Rawah Wilderness Area 
Neota | Neota Wilderness Area 
Comanche | Comanche Peak Wilderness Area 
Cache | Cache la Poudre Wilderness Area


    
- Columns 14-53 that in the original dataset are a one-hot encoded representation of the soil type designation have been replaced by a single column with the ELU code of the soil type, using the following mappings

 ELU Code | Description
----------|------------
 2702|Cathedral family - Rock outcrop complex, extremely stony.
 2703|Vanet - Ratake families complex, very stony.
 2704|Haploborolis - Rock outcrop complex, rubbly.
 2705|Ratake family - Rock outcrop complex, rubbly.
 2706|Vanet family - Rock outcrop complex complex, rubbly.
 2717|Vanet - Wetmore families - Rock outcrop complex, stony.
 3501|Gothic family.
 3502|Supervisor - Limber families complex.
 4201|Troutville family, very stony.
 4703|Bullwark - Catamount families - Rock outcrop complex, rubbly.
 4704|Bullwark - Catamount families - Rock land complex, rubbly.
 4744|Legault family - Rock land complex, stony.
 4758|Catamount family - Rock land - Bullwark family complex, rubbly.
 5101|Pachic Argiborolis - Aquolis complex.
 5151|unspecified in the USFS Soil and ELU Survey.
 6101|Cryaquolis - Cryoborolis complex.
 6102|Gateview family - Cryaquolis complex.
 6731|Rogert family, very stony.
 7101|Typic Cryaquolis - Borohemists complex.
 7102|Typic Cryaquepts - Typic Cryaquolls complex.
 7103|Typic Cryaquolls - Leighcan family, till substratum complex.
 7201|Leighcan family, till substratum, extremely bouldery.
 7202|Leighcan family, till substratum - Typic Cryaquolls complex.
 7700|Leighcan family, extremely stony.
 7701|Leighcan family, warm, extremely stony.
 7702|Granile - Catamount families complex, very stony.
 7709|Leighcan family, warm - Rock outcrop complex, extremely stony.
 7710|Leighcan family - Rock outcrop complex, extremely stony.
 7745|Como - Legault families complex, extremely stony.
 7746|Como family - Rock land - Legault family complex, extremely stony.
 7755|Leighcan - Catamount families complex, extremely stony.
 7756|Catamount family - Rock outcrop - Leighcan family complex, extremely stony.
 7757|Leighcan - Catamount families - Rock outcrop complex, extremely stony.
 7790|Cryorthents - Rock land complex, extremely stony.
 8703|Cryumbrepts - Rock outcrop - Cryaquepts complex.
 8707|Bross family - Rock land - Cryumbrepts complex, extremely stony.
 8708|Rock outcrop - Cryumbrepts - Cryorthents complex, extremely stony.
 8771|Leighcan - Moran families - Cryaquolls complex, extremely stony.
 8772|Moran family - Cryorthents - Leighcan family complex, extremely stony.
 8776|Moran family - Cryorthents - Rock land complex, extremely stony.

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

