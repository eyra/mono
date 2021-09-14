"""Generate fake Google Semantic Location history data"""
import json
import itertools
from datetime import datetime
from collections import OrderedDict
from calendar import monthrange

from zipfile import ZipFile
from faker import Faker
from faker.providers import geo
from faker_schema.faker_schema import FakerSchema
from geopy.distance import geodesic

from google_semantic_location_history.get_faker_schema import get_json_schema, get_faker_schema


YEARS = [2019, 2020, 2021]
MONTHS = [
    "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
    "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
]
# Different behaviour per year
NPLACES = {2019: 50, 2020: 50, 2021: 20}
NACTIVITIES = {2019: 500, 2020: 500, 2021: 250}
TOP_PLACES = {2019: [0.4, 0.3, 0.05], 2020: [0.4, 0.3, 0.05], 2021: [0.8, 0.03, 0.02]}
ACTIVITIES = {
    2019: OrderedDict({
        "CYCLING": 0.3,
        "WALKING": 0.2,
        "IN_VEHICLE": 0.3,
        "IN_TRAIN": 0.2
    }),
    2020: OrderedDict({
        "CYCLING": 0.3,
        "WALKING": 0.2,
        "IN_VEHICLE": 0.3,
        "IN_TRAIN": 0.2
    }),
    2021: OrderedDict({
        "CYCLING": 0.4,
        "WALKING": 0.5,
        "IN_VEHICLE": 0.1
    }),
}
FRACTION_PLACES = {2019: 0.8, 2020: 0.8, 2021: 0.95}

# schema with types
SCHEMA_TYPES = {
    'name': 'company',
    'visitConfidence': 'random_digit_not_null',
    'accuracyMeters': 'random_digit_not_null'
}


def _create_places(total=1, seed=None):
    """Create dictionary with visited places
    Args:
        total (int): number of places
    Returns:
        dict: dictionary with visited places with name, address and location
    """
    fake = Faker('nl_NL')
    if seed is not None:
        fake.seed_instance(seed)
    fake.add_provider(geo)
    places = {}
    latlon = fake.local_latlng(country_code="NL")
    for _ in range(total):
        latitude = fake.unique.coordinate(center=latlon[0], radius=0.05)
        longitude = fake.unique.coordinate(center=latlon[1], radius=0.05)
        place = {
            "name": fake.unique.company(),
            "address": fake.unique.address(),
            "latitude": float(latitude),
            "longitude": float(longitude)
        }
        places.update({fake.unique.pystr_format(): place})
    return places


def _update_data(data, start_date, places, seed=None):
    """ Update GSLH data with specified places, activities and durations
    Args:
        data (dict): data to update
        start_date (datetime.datetime): start date of GSLH data
        places (dict): places to select from
        seed (int): Optionally seed Faker for reproducability
    Returns:
        dict: dictionary with places containing name, address and location
    """
    start_time = start_date.timestamp() * 1.e3
    year = start_date.year
    duration = monthrange(year, start_date.month)[1] * 24 * 60 * 60 * 1.e3 / NACTIVITIES[year]
    duration_place = FRACTION_PLACES[year] * duration
    duration_activity = (1.0 - FRACTION_PLACES[year]) * duration

    elements = OrderedDict()
    for number, place in enumerate(places):
        if number < len(TOP_PLACES[year]):
            elements[place] = TOP_PLACES[year][number]
        else:
            elements[place] = (1.0 - sum(TOP_PLACES[year]))/(NPLACES[year] - len(TOP_PLACES[year]))

    fake = Faker()
    if seed is not None:
        fake.seed_instance(seed)
    start_location = fake.random_element(elements=elements)
    for data_unit in data["timelineObjects"]:
        end_location = fake.random_element(elements=elements)

        if "placeVisit" in data_unit:
            end_time = start_time + duration_place
            data_unit["placeVisit"]["duration"]["startTimestampMs"] = str(int(start_time))
            data_unit["placeVisit"]["duration"]["endTimestampMs"] = str(int(end_time))
            data_unit["placeVisit"]["location"]["address"] = places[start_location]["address"]
            data_unit["placeVisit"]["location"]["placeId"] = start_location
            data_unit["placeVisit"]["location"]["name"] = places[start_location]["name"]
            data_unit["placeVisit"]["location"]["latitudeE7"] = int(places[
                start_location]["latitude"]*1e7)
            data_unit["placeVisit"]["location"]["longitudeE7"] = int(places[
                start_location]["longitude"]*1e7)
            start_time = end_time

        if "activitySegment" in data_unit:
            end_time = start_time + duration_activity
            data_unit["activitySegment"]["duration"]["startTimestampMs"] = str(int(start_time))
            data_unit["activitySegment"]["duration"]["endTimestampMs"] = str(int(end_time))
            data_unit["activitySegment"]['startLocation']['latitudeE7'] = int(places[
                start_location]["latitude"]*1e7)
            data_unit["activitySegment"]['startLocation']['longitudeE7'] = int(places[
                start_location]["longitude"]*1e7)
            data_unit["activitySegment"]['endLocation']['latitudeE7'] = int(places[
                end_location]["latitude"]*1e7)
            data_unit["activitySegment"]['endLocation']['longitudeE7'] = int(places[
                end_location]["latitude"]*1e7)
            data_unit["activitySegment"]["duration"]["activityType"] = fake.random_element(
                elements=ACTIVITIES[year])
            start = (places[start_location]["latitude"], places[start_location]["longitude"])
            end = (places[end_location]["latitude"], places[end_location]["longitude"])
            data_unit["activitySegment"]["distance"] = int(geodesic(start, end).m)
            start_time = end_time

        start_location = end_location

    return data


def write_zipfile(data, zipfile):
    """ Write zipfile with monthly JSON files
    Args:
        data (dict): dict with data per year and month
        zipfile (str): name of zipfile
    """
    with ZipFile(zipfile, 'w') as zip_archive:
        for year, month in data:
            with zip_archive.open(
                'Takeout/Location History/Semantic Location History/' +
                str(year) + '/' + str(year) + '_' + month + '.json', 'w'
            ) as file1:
                file1.write(
                    json.dumps(data[(year, month)]).encode('utf-8')
                )


def fake_data(json_file, seed=0):
    """Return faked json data
    Args:
        json_file: example json file with data to simulate
        seed (int): Optionally seed Faker for reproducability
    Returns:
        dict: dict with summary and DataFrame with extracted data
    """

    # get dict of visited places
    places = _create_places(total=max(NPLACES.values()))

    # Get json schema from json file
    with open(json_file) as file_object:
        json_data = json.load(file_object)
        json_schema = get_json_schema(json_data)

    fake = Faker('nl_NL')
    fake.add_provider(geo)
    faker = FakerSchema(faker=fake, locale='nl_NL')

    faked_data = {}
    for year in YEARS:
        for month in MONTHS:
            schema = get_faker_schema(
                json_schema["properties"],
                custom=SCHEMA_TYPES,
                iterations={"timelineObjects": NACTIVITIES[year]})

            data = faker.generate_fake(schema)
            month_number = datetime.strptime(month[:3], '%b').month
            seed += 1
            json_data = _update_data(
                data, datetime(year, month_number, 1),
                dict(itertools.islice(places.items(), NPLACES[year])),
                seed=seed
            )
            faked_data[(year, month)] = json_data

    return faked_data


if __name__ == '__main__':
    location_data = fake_data("tests/data/2021_JANUARY.json", seed=3)
    write_zipfile(location_data, "tests/data/Location History.zip")
