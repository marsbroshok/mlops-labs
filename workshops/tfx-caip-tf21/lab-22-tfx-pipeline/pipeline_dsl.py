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
"""Covertype training pipeline DSL."""

import os
from typing import Dict, List, Text

from kfp import gcp
from tfx.components.base import executor_spec
from tfx.components.evaluator.component import Evaluator
from tfx.components.example_gen.csv_example_gen.component import CsvExampleGen
from tfx.components.example_validator.component import ExampleValidator
from tfx.components.model_validator.component import ModelValidator
from tfx.components.pusher.component import Pusher
from tfx.components.schema_gen.component import SchemaGen
from tfx.components.statistics_gen.component import StatisticsGen
from tfx.components.trainer.component import Trainer
from tfx.components.transform.component import Transform
from tfx.extensions.google_cloud_ai_platform.pusher import executor as ai_platform_pusher_executor
from tfx.extensions.google_cloud_ai_platform.trainer import executor as ai_platform_trainer_executor
from tfx.orchestration import data_types
from tfx.orchestration import pipeline
from tfx.orchestration.kubeflow import kubeflow_dag_runner
from tfx.orchestration.kubeflow.proto import kubeflow_pb2
from tfx.proto import evaluator_pb2
from tfx.proto import trainer_pb2
from tfx.utils.dsl_utils import external_input
from use_mysql_secret import use_mysql_secret


def _create__pipeline(pipeline_name: Text, 
                      pipeline_root: Text, 
                      data_root: data_types.RuntimeParameter,
                      module_file: data_types.RuntimeParameter, 
                      ai_platform_training_args: Dict[Text, Text],
                      ai_platform_serving_args: Dict[Text, Text],
                      beam_pipeline_args: List[Text]) -> pipeline.Pipeline:
  """Implements the online news pipeline with TFX."""

  examples = external_input(data_root)

  # Brings data into the pipeline or otherwise joins/converts training data.
  example_gen = CsvExampleGen(input=examples)

  # Computes statistics over data for visualization and example validation.
  statistics_gen = StatisticsGen(examples=example_gen.outputs.examples)

  # Generates schema based on statistics files.
  infer_schema = SchemaGen(statistics=statistics_gen.outputs.output)

  # Performs anomaly detection based on statistics and data schema.
  validate_stats = ExampleValidator(
      statistics=statistics_gen.outputs.output, schema=infer_schema.outputs.output)

  # Performs transformations and feature engineering in training and serving.
  transform = Transform(
      examples=example_gen.outputs.examples,
      schema=infer_schema.outputs.output,
      module_file=module_file)

  # Uses user-provided Python function that implements a model using
  # TensorFlow's Estimators API.
  trainer = Trainer(
      custom_executor_spec=executor_spec.ExecutorClassSpec(
          ai_platform_trainer_executor.Executor),
      module_file=module_file,
      transformed_examples=transform.outputs.transformed_examples,
      schema=infer_schema.outputs.output,
      transform_graph=transform.outputs.transform_graph,
      train_args=trainer_pb2.TrainArgs(num_steps=10000),
      eval_args=trainer_pb2.EvalArgs(num_steps=5000),
      custom_config={'ai_platform_training_args': ai_platform_training_args})

  # Uses TFMA to compute a evaluation statistics over features of a model.
  model_analyzer = Evaluator(
      examples=example_gen.outputs.examples,
      model=trainer.outputs.output)

  # Performs quality validation of a candidate model (compared to a baseline).
  model_validator = ModelValidator(
      examples=example_gen.outputs.examples, model=trainer.outputs.output)

  # Checks whether the model passed the validation steps and pushes the model
  # to a file destination if check passed.
  pusher = Pusher(
      custom_executor_spec=executor_spec.ExecutorClassSpec(
          ai_platform_pusher_executor.Executor),
      model=trainer.outputs.output,
      model_blessing=model_validator.outputs.blessing,
      custom_config={'ai_platform_serving_args': ai_platform_serving_args})

  return pipeline.Pipeline(
      pipeline_name=pipeline_name,
      pipeline_root=pipeline_root,
      components=[
          example_gen, statistics_gen, infer_schema, validate_stats, transform,
          trainer, model_analyzer, model_validator, pusher
      ],
      # enable_cache=True,
      beam_pipeline_args=beam_pipeline_args
  )


if __name__ == '__main__':

  # Get evironment settings from environment variables
  pipeline_name = os.environ.get('PIPELINE_NAME')
  project_id = os.environ.get('PROJECT_ID')
  gcp_region = os.environ.get('GCP_REGION')
  pipeline_image = os.environ.get('TFX_IMAGE')
  data_root_uri = os.environ.get('DATA_ROOT_URI')
  artifact_store_uri = os.environ.get('ARTIFACT_STORE_URI')
  runtime_version = os.environ.get('RUNTIME_VERSION')
  python_version = os.environ.get('PYTHON_VERSION')

  # Set values for the compile time parameters
    
  ai_platform_training_args = {
      'project': project_id,
      'region': gcp_region,
      'masterConfig': {
          'imageUri': pipeline_image,
      }
  }

  ai_platform_serving_args = {
      'model_name': 'model_' + pipeline_name,
      'project_id': project_id,
      'runtimeVersion': runtime_version,
      'pythonVersion': python_version
  }

  beam_tmp_folder = '{}/beam/tmp'.format(artifact_store_uri)
  beam_pipeline_args = [
      '--runner=DataflowRunner',
      '--experiments=shuffle_mode=auto',
      '--project=' + project_id,
      '--temp_location=' + beam_tmp_folder,
      '--region=' + gcp_region,
  ]

  # ML Metadata settings
  #_metadata_config = kubeflow_pb2.KubeflowMetadataConfig()
  #_metadata_config.mysql_db_service_host.environment_variable = 'MYSQL_SERVICE_HOST'
  #_metadata_config.mysql_db_service_port.environment_variable = 'MYSQL_SERVICE_PORT'
  #_metadata_config.mysql_db_name.value = 'metadb'
  #_metadata_config.mysql_db_user.environment_variable = 'MYSQL_USERNAME'
  #_metadata_config.mysql_db_password.environment_variable = 'MYSQL_PASSWORD'

  #operator_funcs = [
  #    gcp.use_gcp_secret('user-gcp-sa'),
  #    use_mysql_secret('mysql-credential')
  #]

  
  # Set default values for the pipeline runtime parameters
    
  module_file_param = data_types.RuntimeParameter(
    name='module-file',
    default='{}/{}/{}'.format(artifact_store_uri, pipeline_name, 'transform_train.py'),
    ptype=Text,
  )
  
  data_root_param = data_types.RuntimeParameter(
      name='data-root',
      default=data_root_uri,
      ptype=Text
  )
  
  pipeline_root = '{}/{}'.format(artifact_store_uri, pipeline_name)
    
  
  # Set KubeflowDagRunner settings
  metadata_config = kubeflow_dag_runner.get_default_kubeflow_metadata_config()
  operator_funcs = kubeflow_dag_runner. get_default_pipeline_operator_funcs(use_gcp_sa=True)
    
  runner_config = kubeflow_dag_runner.KubeflowDagRunnerConfig(
      kubeflow_metadata_config=metadata_config,
      pipeline_operator_funcs=operator_funcs,
      tfx_image=pipeline_image)

  # Compile the pipeline
  kubeflow_dag_runner.KubeflowDagRunner(config=runner_config).run(
      _create__pipeline(
          pipeline_name=pipeline_name,
          pipeline_root=pipeline_root,
          data_root=data_root_param,
          module_file=module_file_param,
          ai_platform_training_args=ai_platform_training_args,
          ai_platform_serving_args=ai_platform_serving_args,
          beam_pipeline_args=beam_pipeline_args))
