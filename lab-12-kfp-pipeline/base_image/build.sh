PROJECT_ID=$(gcloud config get-value core/project)
IMAGE_NAME=base_image
TAG=latest

IMAGE_URI="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}"

gcloud builds submit --timeout 15m --tag ${IMAGE_URI} base_image
