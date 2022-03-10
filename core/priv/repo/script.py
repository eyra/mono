"""Script to extract data from Google Semantic History Location zipfile"""
__version__ = "0.1.0"

import json
import re
import zipfile
from datetime import datetime, timedelta

import numpy as np
import pandas as pd

file_re = re.compile(r"^(?:.*\/)?\d+_[A-Z]+.json$")


def parse_datetime(string):
    return datetime.fromisoformat(string.split(".")[0].strip("Z"))


def parse_unix(string):
    return datetime.fromtimestamp(int(string) / 1_000)


def parse_duration(duration):
    try:
        return (
            parse_datetime(duration["startTimestamp"]),
            parse_datetime(duration["endTimestamp"]),
        )
    except KeyError:
        return (
            parse_unix(duration["startTimestampMs"]),
            parse_unix(duration["endTimestampMs"]),
        )


def parse_activity_segment(segment):
    distance = segment.get("distance")
    # Ignore activities without distance
    if distance is None:
        return
    return (
        segment.get("activityType") or "NO_ACTIVITY_TYPE_DETECTED",
        distance,
    ) + parse_duration(segment["duration"])


def parse_timeline_objects(data):
    for item in data["timelineObjects"]:
        # Ignore placeVisits and other types
        segment = item.get("activitySegment")
        if segment:
            parsed = parse_activity_segment(segment)
            # Skip unparsable activities
            if parsed is not None:
                yield parsed


def parse_records(log_error, f):
    try:
        data = json.load(f)
    except json.JSONDecodeError:
        log_error(f"Could not parse: {f.name}")
    else:
        yield from parse_timeline_objects(data)


def parse_zipfile(log_error, zfile):
    for name in zfile.namelist():
        if not file_re.match(name):
            continue

        yield from parse_records(log_error, zfile.open(name))


def add_duration(df):
    df["duration"] = round(
        (df["end_timestamp"] - df["start_timestamp"]) / timedelta(hours=1), 2
    )


def sum_totals(df):
    return pd.Series(
        {
            "Duration (hours)": df["duration"].sum(),
            "Distance (km)": round(df["distance"].sum() / 1000, 2),
        }
    )


def format_results(df):
    results = []
    for activity, activity_df in df.groupby("activity_type"):
        activity_df.index = pd.MultiIndex.from_arrays(
            [
                activity_df.index.map(lambda item: item[0].year),
                activity_df.index.map(lambda item: item[0].month),
            ],
            names=["Year", "Month"],
        )
        results.append(
            {
                "id": activity,
                "title": activity.title().replace("_", " "),
                "data_frame": activity_df,
            }
        )
    return results


def format_errors(errors):
    data_frame = pd.DataFrame()
    data_frame["Messages"] = pd.Series(errors, name="Messages")
    return {"id": "extraction_log", "title": "Extraction log", "data_frame": data_frame}


def process(file_data):
    """Return relevant data from zipfile for years and months"""

    errors = []
    log_error = errors.append

    with zipfile.ZipFile(file_data) as zfile:
        records = parse_zipfile(log_error, zfile)
        df = pd.DataFrame.from_records(
            records,
            columns=["activity_type", "distance", "start_timestamp", "end_timestamp"],
        )

        df = df[
            (df["start_timestamp"] >= np.datetime64("2016-01-01"))
            & (df["start_timestamp"] < np.datetime64("2022-01-01"))
        ]

        add_duration(df)

        df.sort_values(
            ["activity_type", "start_timestamp"], ignore_index=True, ascending=True
        )

        if df.empty:
            return []

        # Create the totals we are after
        df = df.groupby(
            [pd.Grouper(key="start_timestamp", freq="1M"), "activity_type"],
        ).apply(sum_totals)

        # Filter out months without data
        df = df[(df["Duration (hours)"] > 0) & (df["Distance (km)"] > 0)]

        formatted_results = format_results(df)
        # Rename to nice names

        if errors:
            return formatted_results + [format_errors(errors)]
        return formatted_results
