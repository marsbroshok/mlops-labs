FROM gcr.io/deeplearning-platform-release/tf2-cpu.2-0
SHELL ["/bin/bash", "-c"]
RUN apt-get update -y && apt-get -y install kubectl
RUN conda create -n tfx python=3.6 && source activate tfx \
&& pip install -U tfx==0.15 \ 
&& python -m ipykernel install --name tfx 
