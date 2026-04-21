import random


def shuffle_string(s: str) -> str:
    chars = list(s)
    random.shuffle(chars)
    return "".join(chars)
