#!/usr/bin/env bash
export PIP_PACKAGES="tree wheel pip-tools bumpversion tox pysal==2.1.0 psycopg2-binary pandas-gbq pyshp"
export CONDA_PACKAGES="conda-forge qgis"

gcloud beta dataproc clusters create $1 \
--enable-component-gateway --region us-central1 --subnet default \
--zone us-central1-f --master-machine-type n1-standard-4 \
--bucket dataproc_jupiternb \
--master-boot-disk-size 500 --num-workers 2 --worker-machine-type n1-standard-4 \
--worker-boot-disk-size 500 --image-version 1.4-debian9 \
--optional-components ANACONDA,JUPYTER \
--scopes 'https://www.googleapis.com/auth/cloud-platform' --project moovestage \
--initialization-actions 'gs://dataproc_jupiternb/bootstrap_conda.sh','gs://dataproc_jupiternb/install_conda_env.sh' \
--metadata=PIP_PACKAGES="${PIP_PACKAGES}",CONDA_PACKAGES="${CONDA_PACKAGES}"
#--metadata=PIP_PACKAGES="tree wheel pip-tools bumpversion tox pysal==2.1.0 psycopg2-binary pandas-gbq pyshp",CONDA_PACKAGES="conda-forge qgis"


gcloud beta dataproc clusters create jupiter-cluster-mem-test-2 \
--master-machine-type n1-highmem-4 \
--master-boot-disk-size 1000 --num-workers 2 --worker-machine-type n1-highmem-4 \
--worker-boot-disk-size 1000 --image-version 1.4-debian9 \
--optional-components ANACONDA,JUPYTER \
--image-version=1.4 --enable-component-gateway \
--bucket dataproc_jupiternb --project moovestage --region us-central1 \
--metadata 'CONDA_PACKAGES=qgis' \
--initialization-actions gs://dataproc_jupiternb/boot.sh
