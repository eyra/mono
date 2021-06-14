__version__ = '0.1.0'

import zipfile


def process(file_data):
    names = []
    data = []
    zfile = zipfile.ZipFile(file_data)
    for name in zfile.namelist():
        names.append(name)
        data.append((name, zfile.read(name).decode("utf8")))

    return {
        "summary": f"The following files where read: {', '.join(names)}.",
        "data": data
    }
