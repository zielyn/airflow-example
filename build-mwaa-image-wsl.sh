#!/usr/bin/env bash

set -euo pipefail

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
  exit 1
fi

if [[ ! -f "$BASE_DOCKERFILE" || ! -f "$DEV_DOCKERFILE" ]]; then
  printf '%s\n' "Expected Dockerfiles were not found under $IMAGE_DIR/Dockerfiles"
  printf '%s\n' "Ensure the subtree is present and includes generated Dockerfiles."
  exit 1
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
