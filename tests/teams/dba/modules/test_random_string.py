import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", "dags"))

from teams.dba.modules.random_string import shuffle_string


def test_shuffle_string_same_characters():
    original = "helloworld"
    result = shuffle_string(original)
    assert sorted(result) == sorted(original)


def test_shuffle_string_same_length():
    original = "abcdef"
    result = shuffle_string(original)
    assert len(result) == len(original)


def test_shuffle_string_empty():
    assert shuffle_string("") == ""


def test_shuffle_string_single_char():
    assert shuffle_string("x") == "x"


def test_shuffle_string_returns_string():
    result = shuffle_string("test")
    assert isinstance(result, str)
