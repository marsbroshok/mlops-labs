# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import kfp
import os
import uuid
import time
import tempfile


from google.cloud import bigquery
from jinja2 import Template
from kfp.components import func_to_container_op
from kfp.gcp import use_gcp_secret
from kfp.dsl.types import GCPProjectID, GCSPath
from typing import NamedTuple


# Environment settings
_lightweight_component_base_image = os.getenv("LIGHTWEIGHT_COMPONENT_BASE_IMAGE")
_component_url_search_prefix = os.getenv("COMPONENT_URL_SEARCH_PREFIX")

# Helper components

# Create component factories
_component_store = kfp.components.ComponentStore(
    local_search_paths=None,
    url_search_prefixes=[_component_url_search_prefix]
)

_bigquery_query_op = _component_store.load_component('bigquery/query')


@kfp.dsl.pipeline(
    name='Covertype Classifier Training',
    description='The pipeline training and deploying the Covertype classifierpipeline_yaml'
)
def covertype_train(
    project_id:GCPProjectID,
    query:str,
    dataset_id:str,
    training_file_path:GCSPath,
    validation_file_path:GCSPath,
    testing_file_path:GCSPath,
    dataset_location:str ='US'
    ):
    
    
    sample_training_data = _bigquery_query_op(
        query=query,
        project_id=project_id,
        dataset_id=dataset_id,
        table_id='',
        output_gcs_path=training_file_path,
        dataset_location=dataset_location
        )
    
   
    kfp.dsl.get_pipeline_conf().add_op_transformer(use_gcp_secret('user-gcp-sa'))
    
