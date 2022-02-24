"""Script to extract data from Google Semantic History Location zipfile"""
__version__ = "0.1.0"

import json
import itertools
import re
import zipfile

import pandas as pd


#######
pd.set_option("display.max_rows", 500)
pd.set_option("display.max_columns", 500)
pd.set_option("display.width", 1000)
#######

# years and months to extract data for
YEARS = [2016, 2017, 2018, 2019, 2020, 2021]

####### MONTHS = ["JANUARY"]
MONTHS = [
    "JANUARY",
    "FEBRUARY",
    "MARCH",
    "APRIL",
    "MAY",
    "JUNE",
    "JULY",
    "AUGUST",
    "SEPTEMBER",
    "OCTOBER",
    "NOVEMBER",
    "DECEMBER",
]

TEXT = "This study examines the total amount of time spent in activities before and during the COVID-19 pandemic. \
We therefore examined your Google semantic Location History data for 2016, 2017, 2018, 2019, \
2020, and 2021. To be precise, we extracted per month and per year the total hours spent in activities as those were \
recorded by Google such as walking, cycling and running. Also, we extracted \
the number of days spent travelling and the distance travelled in km per month. Finally, you can see the \
number of hours spent travelling per activity and per month and year. \
All the information we extracted is visible on the following tables. "

ERRORS = []
activitiesAll = []


def _activity_type_duration(data):
    """Get duration per activity type
    Args:
        data (dict): Google Semantic Location History data
    Returns:
        dict: duration per activity type in hours
    """
    activityType_duration = []
    for data_unit in data["timelineObjects"]:
        if "activitySegment" in data_unit.keys():
            try:
                activityType = data_unit["activitySegment"]["activityType"]
                start_time = data_unit["activitySegment"]["duration"][
                    "startTimestampMs"
                ]
                end_time = data_unit["activitySegment"]["duration"]["endTimestampMs"]
                activityType_duration.append(
                    {activityType: (int(end_time) - int(start_time)) / (1e3 * 60 * 60)}
                )
            except:
                continue

    # list of activity types
    activities_list = {next(iter(duration)) for duration in activityType_duration}

    # dict of time spend per activity type
    activities = {}
    for activity in activities_list:
        activities[activity] = round(
            sum(
                [
                    duration[activity]
                    for duration in activityType_duration
                    if activity == list(duration.keys())[0]
                ]
            ),
            3,
        )

    return activities


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
            activity_duration += (int(end_time) - int(start_time)) / (
                1e3 * 24 * 60 * 60
            )
    return activity_duration


def _activity_distance(data):
    """Get total distance of activities
    Args:
        data (dict): Google Semantic Location History data
    Returns:
        float: distance of actitvities in km
    """
    activity_distance = 0.0
    for data_unit in data["timelineObjects"]:
        if "activitySegment" in data_unit.keys():
            try:
                activity_distance += (
                    int(data_unit["activitySegment"]["distance"]) / 1000.0
                )
            except:
                continue

    return activity_distance


# This is the new process function
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

                        # check if there is a problem in processing a json files
                        try:
                            data = json.loads(zfile.read(name).decode("utf8"))
                        except:
                            error_message = (
                                "There was a problem in processing the data regarding "
                                + month
                                + " "
                                + str(year)
                            )
                            ERRORS.append(error_message)
                            break

                        activities = _activity_type_duration(data)
                        activitiesAll.extend(activities.keys())

                        results.append(
                            {
                                "Year": year,
                                "Month": month,
                                "Type": dict(itertools.islice(activities.items(), 50)),
                                "Duration [days]": round(_activity_duration(data), 2),
                                "Distance [km]": round(_activity_distance(data), 2),
                            }
                        )
                        break

    # Put results in DataFrame
    data_frame = pd.json_normalize(results)
    data_frame_overall = pd.DataFrame()
    DF_dict = dict()

    if data_frame.empty:
        ERRORS.append("Empty dataframe")
    else:
        activitiesSet = set(activitiesAll)
        data_frame_overall = data_frame[
            ["Year", "Month", "Duration [days]", "Distance [km]"]
        ]

        # rename the columns
        data_frame.columns = data_frame.columns.str.replace("Type.", "")

        for activity in activitiesSet:

            data_frame_activity = data_frame[["Year", "Month", activity]]
            data_frame_activity = data_frame_activity.rename(
                columns={activity: "Nr. of hours"}, errors="raise"
            )
            data_frame_activity = data_frame_activity.round(2)

            activityName = activity.lower()
            if "_" in activityName:
                activityName = activityName.split("_")[1]
                activityName = "Travelled by " + activityName
                if "passenger" in activityName:
                    activityName = "Travelled by passenger vehicle"
                if activityName == "Travelled by activity":
                    activityName = "unknown activity type"
            elif activityName == "cycling":
                activityName = "Travelled by bike"
            elif activityName == "flying":
                activityName = "Travelled by plane"

            DF_dict[activityName] = data_frame_activity.fillna(0)

    # #output results in a csv file

    # data_frame.fillna(0).to_csv("resultPerson2.csv")

    # for k, v in DF_dict:
    #     v.to_csv("resultPerson2.csv")

    results = [
        {"title": "Overall", "data_frame": data_frame_overall},
    ]
    for activityName, data_frame in DF_dict.items():
        data_frame = data_frame[data_frame["Nr. of hours"]>0]
        results.append(
            {"title": activityName, "data_frame": data_frame}
        )
    if ERRORS:
        results.append(
            {
                "title": "Errors",
                "data_frame": pd.DataFrame(pd.Series(ERRORS, name="message")),
            }
        )
    return results


#### This function takes as an input a dataframe, sums the values per column and returns the top columns based on the sum


def _top_cols(dftemp, ncols):
    """Get top activities based on the overall time spent
    Args:
        dftemp (dataframe)
    Returns:
        dataframe: dataframe with only the data of the top activities
    """
    dfsum = dftemp.sum().to_frame().reset_index()
    dfsum = dfsum.sort_values(by=0, ascending=False, inplace=False).head(ncols)
    top_cols = dfsum["index"].tolist()

    return dftemp[top_cols]
