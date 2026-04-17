#!/usr/bin/env bash

set -euo pipefail

export AIRFLOW_HOME="${AIRFLOW_HOME:-/opt/airflow}"
export AIRFLOW__CORE__FERNET_KEY="${AIRFLOW_FERNET_KEY:-$(python - <<'PY'
from cryptography.fernet import Fernet
print(Fernet.generate_key().decode())
PY
)}"

run_startup_script() {
  local startup_script="$AIRFLOW_HOME/startup_script/startup.sh"
  if [[ -f "$startup_script" ]]; then
    bash "$startup_script"
  fi
}

install_requirements() {
  local requirements_file="$AIRFLOW_HOME/requirements/requirements.txt"
  if [[ -f "$requirements_file" ]] && [[ -s "$requirements_file" ]]; then
    pip install -r "$requirements_file"
  fi
}

wait_for_db() {
  python - <<'PY'
import os
import socket
import time

host = os.environ.get("POSTGRES_HOST", "postgres")
port = int(os.environ.get("POSTGRES_PORT", "5432"))

for attempt in range(60):
    try:
        with socket.create_connection((host, port), timeout=2):
            break
    except OSError:
        time.sleep(2)
else:
    raise SystemExit(f"Database {host}:{port} not reachable")
PY
}

bootstrap_airflow() {
  airflow db migrate
  airflow users create \
    --role Admin \
    --username "${AIRFLOW_ADMIN_USERNAME:-admin}" \
    --password "${AIRFLOW_ADMIN_PASSWORD:-test}" \
    --firstname Local \
    --lastname Admin \
    --email "${AIRFLOW_ADMIN_EMAIL:-admin@example.com}" || true
}

start_local_stack() {
  airflow scheduler > "$AIRFLOW_HOME/logs/scheduler.log" 2>&1 &
  exec airflow webserver
}

case "${1:-webserver}" in
  webserver)
    wait_for_db
    run_startup_script
    install_requirements
    bootstrap_airflow
    start_local_stack
    ;;
  requirements-check)
    run_startup_script
    install_requirements
    python -m pip list
    ;;
  startup-check)
    run_startup_script
    env | sort
    ;;
  reset-db)
    wait_for_db
    airflow db reset -y
    airflow db migrate
    ;;
  *)
    exec "$@"
    ;;
esac
