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

    return [
        {
            "title": "Files in the ZIP",
            "data_frame": pd.DataFrame(data, columns=["filename", "compressed size", "size"])
        }
    ]
