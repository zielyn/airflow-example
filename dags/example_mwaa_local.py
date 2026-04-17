from __future__ import annotations

from datetime import datetime

from airflow.decorators import dag, task


@dag(
    dag_id="example_mwaa_local",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["example", "local"],
)
def example_mwaa_local():
    @task
    def emit_context() -> dict[str, str]:
        return {
            "message": "Local MWAA-like workspace is running",
            "dag_folder": "/opt/airflow/dags",
        }

    @task
    def print_context(payload: dict[str, str]) -> None:
        for key, value in payload.items():
            print(f"{key}={value}")

    print_context(emit_context())


example_mwaa_local()
