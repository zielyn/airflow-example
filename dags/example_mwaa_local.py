from __future__ import annotations

from datetime import datetime

from airflow.sdk import dag, task



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
            print(f"lol: {key}={value}")
            
        print(f'Well this should be doing a new version of the task. How to figure this out.')

    @task
    def trying_a_new_task(payload: dict[str, str]) -> None:
        print(f'Will this create a new version? who knows.')

    print_context(emit_context())

    trying_a_new_task(emit_context())


example_mwaa_local()
