import sys
import zipfile
import pandas as pd

def process(file_data):
    names = []
    zfile = zipfile.ZipFile(file_data)
    data = []
    for name in zfile.namelist():
        names.append(name)
        info = zfile.getinfo(name)
        data.append((name, info.compress_size, info.file_size))

    return {
        "summary": f"The following files where read:",
        "data_frames": [
            pd.DataFrame(data, columns=["filename", "compressed size", "size"])
    ]}

if __name__ == "__main__" and len(sys.arv) >= 1:
    from pprint import pprint
    pprint(
        process(sys.argv[1])
    )
