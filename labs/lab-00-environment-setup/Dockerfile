FROM gcr.io/deeplearning-platform-release/tf2-cpu.2-1
RUN apt-get update -y && apt-get -y install kubectl
RUN pip install -U --ignore-installed PyYAML tfx==0.21.0rc0 \
&& pip install -U tensorboard \
&& pip install kfp==0.2.2