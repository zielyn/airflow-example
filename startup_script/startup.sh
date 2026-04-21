#!/usr/bin/env bash

set -u

export LOCAL_MWAA_WORKSPACE=1

# MWAA images use /usr/local/airflow as AIRFLOW_HOME.
# Keep startup script non-fatal so entrypoint can persist customer env vars.
mkdir -p /usr/local/airflow/logs || true
printf '%s\n' 'startup script executed'
