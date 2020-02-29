FROM tensorflow/tfx:0.21.0
WORKDIR /pipeline
COPY transform_train.py ./
COPY schema.pbtxt ./schema/
ENV PYTHONPATH="/pipeline:${PYTHONPATH}"