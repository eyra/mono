"""Test data extraction from Google Semantic History Location zipfile"""
import copy
import json
from zipfile import ZipFile
from io import BytesIO
from pytest import approx
import pandas as pd
from numpy import nan

from google_semantic_location_history import __visit_duration
from google_semantic_location_history import __activity_duration
from google_semantic_location_history import __activity_distance
from google_semantic_location_history import process


ACTIVITY_DATA = {
    "timelineObjects" : [ {
        "activitySegment" : {
            "duration" : {
                "startTimestampMs" : "86400000",
                "endTimestampMs" : "302400000"
            },
            "distance" : 1000,
        }
    }, {
        "activitySegment" : {
            "duration" : {
                "startTimestampMs" : "0",
                "endTimestampMs" : "43200000"
            },
            "distance" : 500,
        }
    },
]}

VISIT_DATA = {
    "timelineObjects" : [ {
        "placeVisit" : {
            "location" : {
                "placeId" : "placeX"
            },
            "duration" : {
                "startTimestampMs" : "0",
                "endTimestampMs" : "86400000"
            }
        }
    }, {
        "placeVisit" : {
            "location" : {
                "placeId" : "placeZ"
            },
            "duration" : {
                "startTimestampMs" : "0",
                "endTimestampMs" : "21600000"
            }
        }
    }, {
        "placeVisit" : {
            "location" : {
                "placeId" : "placeY"
            },
            "duration" : {
                "startTimestampMs" : "0",
                "endTimestampMs" : "43200000"
            }
        }
    }, {
        "placeVisit" : {
            "location" : {
                "placeId" : "placeA"
            },
            "duration" : {
                "startTimestampMs" : "0",
                "endTimestampMs" : "10000000"
            }
        }
    }
]}


def __create_zip():
    """
    returns: zip archive
    """
    archive = BytesIO()
    data_2020 = {**ACTIVITY_DATA, **VISIT_DATA}
    data_2021 = copy.deepcopy(data_2020)
    data_2021["timelineObjects"][0]["placeVisit"]["location"]["placeId"] = "placeA"
    with ZipFile(archive, 'w') as zip_archive:
        # Create files on zip archive
        with zip_archive.open('Takeout/Location History/Semantic Location History/2021/2021_JANUARY.json', 'w') as file1:
            file1.write(json.dumps(data_2020).encode('utf-8'))
        with zip_archive.open('Takeout/Location History/Semantic Location History/2020/2020_JANUARY.json', 'w') as file1:
            file1.write(json.dumps(data_2021).encode('utf-8'))
        with zip_archive.open('Takeout/Location History/Semantic Location History/2018/2018_JANUARY.json', 'w') as file1:
            file1.write(json.dumps(data_2020).encode('utf-8'))
    return archive

def __create_zip_no_matching_files():
    """
    returns: zip archive
    """
    archive = BytesIO()
    data = {**ACTIVITY_DATA, **VISIT_DATA}
    with ZipFile(archive, 'w') as zip_archive:
        # Create files on zip archive
        with zip_archive.open('Takeout/Location History/Semantic Location History/2018/2018_JANUARY.json', 'w') as file1:
            file1.write(json.dumps(data).encode('utf-8'))
        with zip_archive.open('Takeout/Location History/Semantic Location History/2021/2021_MARCH.json', 'w') as file1:
            file1.write(json.dumps(data).encode('utf-8'))
    return archive

def test_visit_duration():
    result = __visit_duration(VISIT_DATA)
    assert result == dict([('placeX', 1.0), ('placeY', 0.5), ('placeZ', 0.25), ('placeA', 0.116)])

def test_activity_duration():
    result = __activity_duration(ACTIVITY_DATA)
    assert result == approx(3.0)

def test_activity_distance():
    result = __activity_distance(ACTIVITY_DATA)
    assert result == approx(1.5)

def test_process():
    result = process(__create_zip())
    expected = pd.json_normalize([
        {'Year': 2020, 'Month': 'JANUARY', 'Number of Places': 3, 'Places Duration [days]': 1.866, 'Activity Duration [days]': 0.0, 'Activity Distance [km]': 0.0, 'Place 1 [days]': 1.116, 'Place 2 [days]': 0.5, 'Place 3 [days]': 0.25, 'Place 4 [days]': 0.},
        {'Year': 2021, 'Month': 'JANUARY', 'Number of Places': 4, 'Places Duration [days]': 1.866, 'Activity Duration [days]': 0.0, 'Activity Distance [km]': 0.0, 'Place 1 [days]': 0., 'Place 2 [days]': 0.5, 'Place 3 [days]': 0.25, 'Place 4 [days]': 1.0}])
    assert result["data"] == expected.to_csv(index=False)

def test_process_no_matching_files():
    result = process(__create_zip_no_matching_files())
    expected = pd.DataFrame()
    assert result["data"] == expected.to_csv(index=False)