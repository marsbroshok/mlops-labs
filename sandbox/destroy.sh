SUBSTITUTIONS=\
_TERRAFORM_FOLDER=terraform

gcloud builds submit . --config cloudbuild-destroy.yaml --substitutions $SUBSTITUTIONS