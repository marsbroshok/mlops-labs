SUBSTITUTIONS=\
_TERRAFORM_FOLDER=terraform

gcloud builds submit . --config cloudbuild-create.yaml --substitutions $SUBSTITUTIONS