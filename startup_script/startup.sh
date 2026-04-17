#!/usr/bin/env bash

set -euo pipefail

export LOCAL_MWAA_WORKSPACE=1
mkdir -p /opt/airflow/logs
printf '%s\n' 'startup script executed'
