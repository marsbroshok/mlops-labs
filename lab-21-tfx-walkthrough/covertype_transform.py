# Copyright 2019 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#            http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Covertype dataset transformation routines."""

import tensorflow as tf
import tensorflow_transform as tft

NUMERIC_FEATURES_KEYS = [
    'Elevation', 'Aspect', 'Slope', 'Horizontal_Distance_To_Hydrology',
    'Vertical_Distance_To_Hydrology', 'Horizontal_Distance_To_Roadways',
    'Hillshade_9am', 'Hillshade_Noon', 'Hillshade_3pm',
    'Horizontal_Distance_To_Fire_Points'
]

CATEGORICAL_FEATURES_KEYS = ['Wilderness_Area', 'Soil_Type']

LABEL_KEY = 'Cover_Type'


def _transformed_name(key):
  return key + '_xf'


def _fill_in_missing(x):
  """Replaces missing values and coverts a SparseTensor to a DenseTensor."""

  default_value = '' if x.dtype == tf.string else 0
  return tf.squeeze(
      tf.sparse.to_dense(
          tf.SparseTensor(x.indices, x.values, [x.dense_shape[0], 1]),
          default_value),
      axis=1)


def preprocessing_fn(inputs):
  """Preprocesses Covertype Dataset."""

  outputs = {}

  # Scale numerical features
  for key in NUMERIC_FEATURES_KEYS:
    outputs[_transformed_name(key)] = tft.scale_to_z_score(
        _fill_in_missing(inputs[key]))

  # Generate vocabularies and maps categorical features
  for key in CATEGORICAL_FEATURES_KEYS:
    outputs[_transformed_name(key)] = tft.compute_and_apply_vocabulary(
        x=_fill_in_missing(inputs[key]), num_oov_buckets=1, vocab_filename=key)

  # Convert Cover_Type from 1-7 to 0-6
  outputs[_transformed_name(LABEL_KEY)] = _fill_in_missing(
      inputs[LABEL_KEY]) - 1

  return outputs
