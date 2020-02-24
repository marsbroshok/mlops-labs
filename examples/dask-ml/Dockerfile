FROM gcr.io/deeplearning-platform-release/base-cpu
RUN pip install -U fire dask-ml
WORKDIR /app
COPY hypertune.py .

ENTRYPOINT ["python", "hypertune.py"]
