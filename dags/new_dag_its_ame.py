from __future__ import annotations

from datetime import datetime

from airflow.sdk import dag, task

@dag(
    dag_id="new_dag_its_ame",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["example", "new_dag_its_ame"],
)
def new_dag_its_ame():
    @task
    def build_sentences() -> list[str]:
        # Returning a list here creates exactly two dynamically mapped task instances downstream.
        return [
            "This workflow creates dynamic tasks in Airflow.",
            "Their outputs are merged into one paragraph for a final task.",
        ]

    @task
    def make_dynamic_line(sentence: str) -> str:
        return sentence.strip()

    @task
    def combine_into_paragraph(lines: list[str]) -> str:
        paragraph = " ".join(lines)
        print(f"Combined paragraph: {paragraph}")
        return paragraph

    @task
    def use_paragraph(paragraph: str) -> None:
        print("Final task received paragraph:")
        print(paragraph)

    # Dependencies and Running the DAG
    dynamic_lines = make_dynamic_line.expand(sentence=build_sentences())
    paragraph = combine_into_paragraph(dynamic_lines)
    use_paragraph(paragraph)

new_dag_its_ame()