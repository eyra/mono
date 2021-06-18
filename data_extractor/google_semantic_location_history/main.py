"Main program to test google_semantic_location history script"
import io
import pandas as pd
from google_semantic_location_history import process


if __name__ == '__main__':
    result = process("tests/data/Location History.zip")
    print("\nRaw result:")
    print(result)
    data_frame = pd.read_csv(io.StringIO(result["data"]), sep=",")
    pd.options.display.max_columns = 9
    print("\nDataframe:")
    print(data_frame)
