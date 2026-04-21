#!/usr/bin/env bash

set -euo pipefail

MODE="${1:-build}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$ROOT_DIR/.env"
ENV_EXAMPLE_FILE="$ROOT_DIR/.env.example"

if ! command -v docker >/dev/null 2>&1; then
  printf '%s\n' "docker is required in WSL PATH."
  exit 1
fi

read_env_var() {
  local key="$1"
  local default_value="$2"
  local file_path=""
  local value=""

  if [[ -f "$ENV_FILE" ]]; then
    file_path="$ENV_FILE"
  elif [[ -f "$ENV_EXAMPLE_FILE" ]]; then
    file_path="$ENV_EXAMPLE_FILE"
  else
    printf '%s' "$default_value"
    return 0
  fi

  value="$(sed -n "s/^${key}=//p" "$file_path" | tail -n 1)"

  # Normalize values read from .env files created on Windows.
  # This strips CRLF artifacts, surrounding quotes, and leading/trailing spaces.
  value="${value%$'\r'}"
  value="${value#\"}"
  value="${value%\"}"
  value="$(printf '%s' "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

  if [[ -z "$value" ]]; then
    printf '%s' "$default_value"
  else
    printf '%s' "$value"
  fi
}

AIRFLOW_VERSION="$(read_env_var AIRFLOW_VERSION 3.0.6)"
MWAA_IMAGE_REPOSITORY="$(read_env_var MWAA_IMAGE_REPOSITORY amazon-mwaa-docker-images/airflow)"

IMAGE_DIR="$ROOT_DIR/st/amazon-mwaa-docker-images/images/airflow/$AIRFLOW_VERSION"
BASE_DOCKERFILE="$IMAGE_DIR/Dockerfiles/Dockerfile.base"
DEV_DOCKERFILE="$IMAGE_DIR/Dockerfiles/Dockerfile-dev"

if [[ ! -d "$IMAGE_DIR" ]]; then
  printf '%s\n' "Missing subtree Airflow version directory: $IMAGE_DIR"
  printf '%s\n' "Available versions under subtree:"
  ls -1 "$ROOT_DIR/st/amazon-mwaa-docker-images/images/airflow" | sed 's/^/  - /'
  printf '%s\n' "Tip: check AIRFLOW_VERSION in .env for hidden CRLF or quotes."
  exit 1
fi

if [[ ! -f "$BASE_DOCKERFILE" || ! -f "$DEV_DOCKERFILE" ]]; then
  printf '%s\n' "Expected Dockerfiles were not found under $IMAGE_DIR/Dockerfiles"
  printf '%s\n' "Ensure the subtree is present and includes generated Dockerfiles."
  exit 1
fi

normalize_line_endings() {
  local target_dir="$1"

  # Convert CRLF -> LF for shell and bootstrap executables consumed by Docker build.
  # This avoids runtime failures like "cannot execute: required file not found" when
  # script shebang lines include carriage returns from Windows checkouts.
  while IFS= read -r -d '' file; do
    sed -i 's/\r$//' "$file"
  done < <(
    find "$target_dir" -type f \
      \( -name "*.sh" \
      -o -name "build.sh" \
      -o -name "run.sh" \
      -o -name "temporary-pip-install" \
      -o -path "*/bin/*" \
      -o -path "*/bootstrap/*" \
      -o -path "*/bootstrap-dev/*" \
      \) -print0
  )
}

printf '%s\n' "Normalizing script line endings under $IMAGE_DIR"
normalize_line_endings "$IMAGE_DIR"

if [[ "$MODE" == "--normalize-only" ]]; then
  printf '%s\n' "Normalization complete (no image build requested)."
  exit 0
fi

printf '%s\n' "Building ${MWAA_IMAGE_REPOSITORY}:${AIRFLOW_VERSION}-base"
docker build \
  -f "$BASE_DOCKERFILE" \
  -t "${MWAA_IMAGE_REPOSITORY}:${AIRFLOW_VERSION}-base" \
  "$IMAGE_DIR"

printf '%s\n' "Building ${MWAA_IMAGE_REPOSITORY}:${AIRFLOW_VERSION}-dev"
docker build \
  -f "$DEV_DOCKERFILE" \
  -t "${MWAA_IMAGE_REPOSITORY}:${AIRFLOW_VERSION}-dev" \
  "$IMAGE_DIR"

printf '%s\n' "MWAA image build complete."
printf '%s\n' "Next: docker compose --env-file .env -f docker/docker-compose-local.yml up -d"
