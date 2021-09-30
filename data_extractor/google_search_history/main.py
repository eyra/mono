"Main program to test google_search_history script"
from pathlib import Path
from google_search_history import process


if __name__ == '__main__':

    file_data = Path('tests/data/Takeout.zip')
    result = process(file_data)
    data_frame = result["data_frames"]
    print(data_frame)
