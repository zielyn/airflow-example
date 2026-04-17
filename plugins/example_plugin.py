from __future__ import annotations

from flask_appbuilder import BaseView, expose
from airflow.plugins_manager import AirflowPlugin


class LocalDevView(BaseView):
    route_base = "/local-dev"

    @expose("/")
    def list(self):
        return self.render_template("airflow/main.html", content="Local plugin loaded")


class ExampleLocalPlugin(AirflowPlugin):
    name = "example_local_plugin"
    appbuilder_views = [
        {
            "name": "Local Dev",
            "category": "Admin",
            "view": LocalDevView(),
        }
    ]
