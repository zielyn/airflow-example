# Local MWAA Development Workspace

This repository bootstraps a local, MWAA-like Apache Airflow development environment for Windows machines running WSL2 and Docker Desktop. It is not an AWS deployment project. The goal is fast local DAG, plugin, dependency, and startup-script iteration with directory conventions that map cleanly to Amazon MWAA.

## What you get

- A Docker-based Airflow stack with a Postgres metadata database
- A bash helper script for the common local-runner flows
- A VS Code devcontainer for consistent editor tooling
- MWAA-style asset folders: `dags`, `plugins`, `requirements`, and `startup_script`
- Starter code and docs for local development

## Prerequisites

This workspace assumes a Windows host.

1. Install WSL2.
2. Install Docker Desktop and enable WSL integration for the distro you use for development.
3. Open this repository from WSL or reopen it in the devcontainer.
4. Ensure `docker`, `docker compose`, `python3`, and `pip3` are available in that environment.

This workspace is designed for local development. It does not attempt to exactly recreate the managed AWS control plane or production MWAA networking and IAM behavior.

## Quick start

```bash
cp .env.example .env
./mwaa-local-env validate-prereqs
./build-mwaa-image-wsl.sh
docker compose --env-file .env -f docker/docker-compose-local.yml up -d
```

The local stack now runs on the MWAA image built from the vendored subtree source at `st/amazon-mwaa-docker-images`.

Airflow UI:

- URL: `http://localhost:8080`
- Username: `admin`
- Password: `test`

## Common commands

```bash
./mwaa-local-env init-env
./mwaa-local-env validate-prereqs
./mwaa-local-env build-image
./build-mwaa-image-wsl.sh
./mwaa-local-env start
./mwaa-local-env stop
./mwaa-local-env reset-db
./mwaa-local-env test-requirements
./mwaa-local-env test-startup-script
./mwaa-local-env open-shell
```

Direct startup without helper script:

```bash
docker compose --env-file .env -f docker/docker-compose-local.yml up -d
```

## Workspace layout

```text
.
|-- .devcontainer/
|-- dags/
|-- docker/
|   |-- config/
|   |-- script/
|   |-- Dockerfile
|   |-- docker-compose-local.yml
|   `-- docker-compose-resetdb.yml
|-- logs/
|-- plugins/
|-- requirements/
|-- startup_script/
`-- mwaa-local-env
```

### MWAA runtime mapping

Root folders remain the source of truth and are mounted into MWAA container paths:

- `dags` -> `/usr/local/airflow/dags`
- `plugins` -> `/usr/local/airflow/plugins`
- `requirements` -> `/usr/local/airflow/requirements`
- `startup_script` -> `/usr/local/airflow/startup`
- `logs` -> `/usr/local/airflow/logs`

## Working with MWAA assets

### DAGs

Put DAG code in `dags/`. The included example DAG verifies the stack is healthy and shows the expected authoring style.

### Plugins

Put custom plugin code in `plugins/`. The included example plugin is intentionally minimal so it loads cleanly on Airflow 3.

### Python dependencies

Add package pins to `requirements/requirements.txt`.

To validate dependency installation without starting the full stack:

```bash
./mwaa-local-env test-requirements
```

If you are targeting MWAA, keep custom requirements constrained to versions that are compatible with the pinned Airflow version in this repository.

### Startup script

Use `startup_script/startup.sh` for local environment setup that should run when the Airflow container starts.

To test it directly:

```bash
./mwaa-local-env test-startup-script
```

## Devcontainer

The devcontainer gives you Python tooling plus access to the host Docker daemon, so you can run the same helper commands from inside VS Code.

Open the command palette and run `Dev Containers: Reopen in Container` after Docker Desktop and WSL integration are working.

When you start the Airflow stack from WSL or the devcontainer, Docker Desktop publishes the Airflow UI to your Windows host on `http://localhost:8080` by default.

## Configuration

Copy `.env.example` to `.env` and override values as needed.

Key settings:

- `AIRFLOW_VERSION`: Airflow version installed in the local image
- `AIRFLOW_EXECUTOR`: defaults to `LocalExecutor`
- `AIRFLOW_API_PORT`: published port for the Airflow API/UI (defaults to `8080`)
- `AIRFLOW_ADMIN_USERNAME` and `AIRFLOW_ADMIN_PASSWORD`: local login credentials
- `AWS_*`: optional credentials for local AWS operator testing

## Subtree maintenance

This repository vendors `aws/amazon-mwaa-docker-images` as a git subtree at `st/amazon-mwaa-docker-images`.

### Current subtree path

- `st/amazon-mwaa-docker-images`

### Update subtree from upstream

Run from the repository root:

```bash
git subtree pull --prefix=st/amazon-mwaa-docker-images https://github.com/aws/amazon-mwaa-docker-images.git main
```

This fetches upstream `main` and merges new changes into the subtree path.

### Recreate subtree (only if needed)

If the subtree was removed or needs to be re-added:

```bash
git subtree add --prefix=st/amazon-mwaa-docker-images https://github.com/aws/amazon-mwaa-docker-images.git main
```

### Inspect subtree provenance

```bash
git log --oneline --decorate -- st/amazon-mwaa-docker-images
git show --stat --oneline HEAD
```

Look for commit messages like:

- `Add 'st/amazon-mwaa-docker-images/' from commit '<sha>'`
- `Split 'st/amazon-mwaa-docker-images/' into commit '<sha>'`

### Optional: track a named remote

Using a named remote can make pull commands shorter:

```bash
git remote add mwaa-upstream https://github.com/aws/amazon-mwaa-docker-images.git
git fetch mwaa-upstream
git subtree pull --prefix=st/amazon-mwaa-docker-images mwaa-upstream main
```

If the remote already exists, skip the add step.

## Troubleshooting

### The stack fails to start

- Run `./mwaa-local-env stop` and then `./mwaa-local-env start`
- If the metadata DB is inconsistent, run `./mwaa-local-env reset-db`
- Check container logs with `docker compose --env-file .env -f docker/docker-compose-local.yml logs`

### DAG import errors

- Validate your Python dependencies with `./mwaa-local-env test-requirements`
- Open a shell with `./mwaa-local-env open-shell` and run `airflow dags list-import-errors`

### Docker commands fail in VS Code

- Confirm the folder is opened from WSL or the devcontainer
- Confirm Docker Desktop WSL integration is enabled for your distro

## Scope notes

This workspace is deliberately limited to local development. It does not include Terraform, CDK, CI, or packaging for deployment to a real MWAA environment.
