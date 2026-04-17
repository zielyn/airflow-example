FROM public.ecr.aws/docker/library/python:3.11-slim-bookworm

ARG AIRFLOW_VERSION=2.10.3
ARG AIRFLOW_CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-3.11.txt"

ENV DEBIAN_FRONTEND=noninteractive
ENV AIRFLOW_HOME=/opt/airflow
ENV PIP_NO_CACHE_DIR=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       build-essential \
       curl \
       git \
       libpq-dev \
       procps \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --home-dir ${AIRFLOW_HOME} --shell /bin/bash airflow

RUN pip install --upgrade pip setuptools wheel \
    && pip install \
       "apache-airflow[postgres]==${AIRFLOW_VERSION}" \
       --constraint "${AIRFLOW_CONSTRAINT_URL}" \
    && pip install \
       "apache-airflow-providers-amazon>=9.0.0,<10.0.0" \
       --constraint "${AIRFLOW_CONSTRAINT_URL}"

WORKDIR ${AIRFLOW_HOME}

COPY docker/script/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chown airflow:airflow /entrypoint.sh

USER airflow

ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"]
