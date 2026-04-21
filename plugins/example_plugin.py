from __future__ import annotations

from airflow.plugins_manager import AirflowPlugin

class ExampleLocalPlugin(AirflowPlugin):
    name = "example_local_plugin"

