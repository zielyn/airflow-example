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
}

start_local_stack() {
  local pids=()

  # Start each required Airflow service in the background and track child PIDs.
  airflow scheduler > "$AIRFLOW_HOME/logs/scheduler.log" 2>&1 &
  pids+=("$!")

  airflow triggerer > "$AIRFLOW_HOME/logs/triggerer.log" 2>&1 &
  pids+=("$!")

  airflow dag-processor > "$AIRFLOW_HOME/logs/dag_processor.log" 2>&1 &
  pids+=("$!")

  airflow api-server > "$AIRFLOW_HOME/logs/api_server.log" 2>&1 &
  pids+=("$!")

  trap 'kill "${pids[@]}" 2>/dev/null || true' TERM INT

  # Exit if any child process exits unexpectedly.
  wait -n "${pids[@]}"
}

case "${1:-api-server}" in
  api-server)
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
