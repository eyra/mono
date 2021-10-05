"""Script to extract data from Google Semantic History Location zipfile"""
__version__ = '0.1.0'

import json
import itertools
import re
import zipfile

import pandas as pd


# years and months to extract data for
YEARS = [2019, 2020, 2021]
MONTHS = ["JANUARY"]
NPLACES = 3
TEXT = "This study examines the change in travel behaviour during the COVID-19 pandemic. \
We therefore examined your Google semantic Location History data for January in 2019, \
2020, and 2021. To be precise, we extracted per month the total number of visited places, \
and the number of days spend per place for the three most visited places. Also, we extracted \
the number of days spend in places and travelling, and the travelled distance in km."


def _visit_duration(data):
    """Get duration per visited place
    Args:
        data (dict): Google Semantic Location History data
    Returns:
        dict: duration per visited place, sorted in descending order
    """
    placevisit_duration = []
    for data_unit in data["timelineObjects"]:
        if "placeVisit" in data_unit:
            address = data_unit["placeVisit"]["location"]["placeId"]
            start_time = data_unit["placeVisit"]["duration"]["startTimestampMs"]
            end_time = data_unit["placeVisit"]["duration"]["endTimestampMs"]
            placevisit_duration.append(
                {address: (int(end_time) - int(start_time))/(1e3*24*60*60)})

    # list of places visited
    address_list = {next(iter(duration)) for duration in placevisit_duration}

    # dict of time spend per place
    places = {}
    for address in address_list:
        places[address] = round(sum(
            [duration[address] for duration in placevisit_duration
                if address == list(duration.keys())[0]]), 3)
    # Sort places to amount of time spend
    places = dict(sorted(places.items(), key=lambda kv: kv[1], reverse=True))

    return places


def _activity_duration(data):
    """Get total duration of activities
    Args:
        data (dict): Google Semantic Location History data
    Returns:
        float: duration of actitvities in days
    """
    activity_duration = 0.0
    for data_unit in data["timelineObjects"]:
        if "activitySegment" in data_unit.keys():
            start_time = data_unit["activitySegment"]["duration"]["startTimestampMs"]
            end_time = data_unit["activitySegment"]["duration"]["endTimestampMs"]
            activity_duration += (int(end_time) - int(start_time))/(1e3*24*60*60)
    return activity_duration


def _activity_distance(data):
    """Get total distance of activities
    Args:
        data (dict): Google Semantic Location History data
    Returns:
        float: duration of actitvities in days
    """
    activity_distance = 0.0
    for data_unit in data["timelineObjects"]:
        if "activitySegment" in data_unit.keys():
            activity_distance += int(data_unit["activitySegment"]["distance"])/1000.0

    return activity_distance


def process(file_data):
    """Return relevant data from zipfile for years and months
    Args:
        file_data: zip file or object

    Returns:
        dict: dict with summary and DataFrame with extracted data
    """
    results = []
    filenames = []

    # Extract info from selected years and months
    with zipfile.ZipFile(file_data) as zfile:
        file_list = zfile.namelist()
        for year in YEARS:
            for month in MONTHS:
                for name in file_list:
                    monthfile = f"{year}_{month}.json"
                    if re.search(monthfile, name) is not None:
                        filenames.append(monthfile)
                        data = json.loads(zfile.read(name).decode("utf8"))
                        places = _visit_duration(data)
                        results.append({
                            "Year": year,
                            "Month": month,
                            "Top Places": dict(itertools.islice(places.items(), NPLACES)),
                            "Number of Places": len(places),
                            "Places Duration [days]": round(
                                sum(value for value in places.values()), 3),
                            "Activity Duration [days]": round(_activity_duration(data), 3),
                            "Activity Distance [km]": round(_activity_distance(data), 3)
                        })
                        break

    # Put results in DataFrame
    data_frame = pd.json_normalize(results)

    # Anonymize by replace PlaceIds with numbers
    number = 0
    for column in data_frame.columns:
        if column.split(".")[0] == "Top Places":
            number += 1
            data_frame.rename(columns={column: f"Place {number} [days]"}, inplace=True)

    return {
        "summary": TEXT,
        "data_frames": [
            data_frame.fillna(0)
        ]
    }
