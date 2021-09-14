"Main program to test google_semantic_location history script"
from google_semantic_location_history import process


if __name__ == '__main__':
    result = process("tests/data/Location History.zip")
    print("Summary:\n", result["summary"])
    print("Dataframe\n", result["data_frames"])
