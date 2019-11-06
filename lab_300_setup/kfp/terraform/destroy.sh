#!/bin/bash

terraform destroy -var 'project_id=jk-caip' -var 'region=us-central1' -var 'zone=us-central1-a' -var 'name_prefix=env3'