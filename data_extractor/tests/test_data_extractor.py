from data_extractor import process
from pathlib import Path

DATA_PATH = Path(__file__).parent / "data"

def test_hello_world():
    result = process(DATA_PATH.joinpath("hello.zip").open("rb"))
    assert result["summary"] == 'The following files where read: hello/, hello/world.txt.'
    assert len(result["data"]) == 2
