<<<<<<< HEAD:st/amazon-mwaa-docker-images/tests/images/airflow/3.2.0/conftest.py
"""Shared fixtures and utilities for config tests."""

import os
import pytest
from unittest.mock import patch, MagicMock
from typing import Dict, Any, Generator
import subprocess
import sys

def pytest_configure(config):
    airflow_version = "3.2.0"
    requirements_path = os.path.join(
        os.path.dirname(__file__),
        "requirements.txt"
    )
    airflow_path = os.path.abspath(
        os.path.join(
            os.path.dirname(__file__),
            "..",
            "..",
            "..",
            "..",
            "images",
            "airflow",
            airflow_version,
            "python"
        )
    )
    # Add to Python path
    sys.path.insert(0, airflow_path)

    os.environ["MWAA__CORE__TESTING_MODE"] = "true"
    os.environ["MWAA__CORE__STARTUP_SCRIPT_PATH"] = "../../startup/startup.sh"

    if os.path.exists(requirements_path):
        try:
            print(f"Installing requirements from: {requirements_path}")
            subprocess.check_call([
                "pip",
                "install",
                "--no-cache-dir",
                "-r",
                requirements_path
            ])
        except subprocess.CalledProcessError as e:
            print(f"Error installing requirements: {e}")
            raise
    else:
        print(f"Requirements file not found at: {requirements_path}")


@pytest.fixture
def env_helper(monkeypatch):
    class EnvHelper:
        def set(self, vars):
            for k, v in vars.items():
                monkeypatch.setenv(k, v)

        def delete(self, keys):
            for k in keys:
                monkeypatch.delenv(k, raising=False)

    return EnvHelper()
=======
"""Shared fixtures and utilities for config tests."""

import os
import pytest
from unittest.mock import patch, MagicMock
from typing import Dict, Any, Generator
import subprocess
import sys

def pytest_configure(config):
    airflow_version = "3.2.1"
    requirements_path = os.path.join(
        os.path.dirname(__file__),
        "requirements.txt"
    )
    airflow_path = os.path.abspath(
        os.path.join(
            os.path.dirname(__file__),
            "..",
            "..",
            "..",
            "..",
            "images",
            "airflow",
            airflow_version,
            "python"
        )
    )
    # Add to Python path
    sys.path.insert(0, airflow_path)

    os.environ["MWAA__CORE__TESTING_MODE"] = "true"
    os.environ["MWAA__CORE__STARTUP_SCRIPT_PATH"] = "../../startup/startup.sh"

    if os.path.exists(requirements_path):
        try:
            print(f"Installing requirements from: {requirements_path}")
            subprocess.check_call([
                "pip",
                "install",
                "--no-cache-dir",
                "-r",
                requirements_path
            ])
        except subprocess.CalledProcessError as e:
            print(f"Error installing requirements: {e}")
            raise
    else:
        print(f"Requirements file not found at: {requirements_path}")


@pytest.fixture
def env_helper(monkeypatch):
    class EnvHelper:
        def set(self, vars):
            for k, v in vars.items():
                monkeypatch.setenv(k, v)

        def delete(self, keys):
            for k in keys:
                monkeypatch.delenv(k, raising=False)

    return EnvHelper()
>>>>>>> 72a97b2967a22ec1bd207f3e68db75e52ab1848f:st/amazon-mwaa-docker-images/tests/images/airflow/3.2.1/conftest.py
