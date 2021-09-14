""" Script to create simulated Google Browser History data """

import random
import string
import json
import re

from zipfile import ZipFile
from pathlib import Path
from datetime import datetime, time
from faker import Faker

import pandas as pd
import pytz


NEWS = ("news.google.com", "nieuws.nl", "nos.nl", "rtlnieuws.nl", "nu.nl",
        "at5.nl", "ad.nl", "bd.nl", "telegraaf.nl", "volkskrant.nl",
        "parool.nl", "metronieuws.nl", "nd.nl", "nrc.nl", "rd.nl",
        "trouw.nl")

PERIODS = {'before': ["20-10-2020 13:30:00", "23-01-2021 20:59:59"],
           'during': ["23-01-2021 21:00:00", "28-04-2021 04:29:59"],
           'after': ["28-04-2021 04:29:59", "23-07-2021 04:50:34"]}

TRANSITION = ("LINK", "GENERATED", "RELOAD")

ZONE = pytz.utc


def _create_website(num: int, perc: float, fake=False):
    """ Create list with n number of random (news) websites.
    Args:
        num: int,
            number of websites you want to generate
        perc: float (0-1),
            percentage of websites that need to be news websites
        fake: boolean,
            if False existing URLs are selected from urldata.csv
            if True fake URLs are created using Faker
    Return:
        websites: list,
            created websites in url format
    """
    if fake:
        websites = [Faker().profile()['website'][0] for i in range(num)]
        for i in range(round(num*perc)):
            site = f'https://{random.choice(NEWS)}'
            websites[i] = f"{site}/{'/'.join(websites[i].split('/')[3:])}"
    else:
        for file in Path('.').glob('**/*'):
            if re.search('urldata.csv', f'{file}'):
                urldata = pd.read_csv(file)
        websites = [random.choice(urldata['url']) for i in range(num)]
        for i in range(round(num*perc)):
            news = random.choice(NEWS)
            websites[i] = f"{news}/{'/'.join(websites[i].split('/')[1:])}"
        url = 'https://{}'
        websites = [url.format(website) for website in websites]
    random.shuffle(websites)
    return websites


def _create_date(num: int, start: datetime, end: datetime, time_perc: float):
    """ Creates list with random dates between given start and end time
        (with bias towards evening times)
    Args:
        num int,
            number of dates that need to be created
        start: datetime,
            earliest date
        end: datetime,
            latest date
        time_perc: float (0-1),
            percentage more evening times
    Return:
        dates: list,
            created list of dates
    """
    frmt = '%d-%m-%Y %H:%M:%S'
    stime = datetime.strptime(start, frmt)
    etime = datetime.strptime(end, frmt)
    timestamps = []
    stop = 0
    while len(timestamps) < num:
        date = stime + random.random() * (etime - stime)
        while stop < round(num * time_perc):
            evening = time(random.randint(18, 23),
                           random.randint(0, 59),
                           random.randint(0, 59))
            date = datetime.combine(date, evening)
            stop += 1
        date_zone = ZONE.localize(date)
        timestamp = int(datetime.timestamp(date_zone)*1e6)
        timestamps.append(timestamp)
    timestamps.sort()
    return timestamps


def _create_bins(num):
    """ Randomly distribute n over 3 bins
        (i.e., number of searches before, during, and after curfew)
    Args:
        num: int,
            total number of searches that should be in the
            BrowserHistory file
    Returns:
        bins: list,
            number of searches that will be generated for
            before, during, and after curfew
    """
    bin_size = int(num*(1/3))
    before = bin_size + random.randint(0, bin_size) * random.randint(-1, 1)
    during = round((num - before)/2)
    after = num - before - during
    bins = {'before': before, 'during': during, 'after': after}
    return bins


def create_zip(browser_hist):
    """ Saves created BrowserHistory in zipped file
    Args:
        browser_history: json.dumps,
            created browser history dictionary
    """
    for file_ in Path('.').glob('**/*'):
        if Path(file_).name == 'data':
            path = file_
    with ZipFile(path / 'Takeout.zip', 'w') as zipped_f:
        zipped_f.writestr("Takeout/Chrome/BrowserHistory.json", browser_hist)
        return Path(path, 'Takeout.zip')


def browserhistory(num: int, site_diff: float, time_diff: bool,
                   seed: int, fake=False):
    """ Create simulated BrowserHistory dictionary
    Args:
        num: int,
            number of browser searches
        site_diff: float (0-1),
            percentage of websites that need to be news websites
        time_diff: float (0-1),
            percentage of timestamps that need to be
            evening times (during curfew)
        seed: int,
            sets seed for entire script
        fake: boolean,
            if False existing URLs are selected from urldata.csv
            if True fake URLs are created using Faker
    Return:
        browser_hist: dict,
            simulated BrowserHistory
    """
    # set seeds
    random.seed(seed)
    Faker.seed(str(seed))
    # create random bin sizes for each period (before, during, after)
    parts = _create_bins(num)
    # create browserhistory data
    results = []
    for moment in PERIODS:
        # simulate dates
        if moment == 'during':
            perc = 0.15+site_diff
            dates = _create_date(num=parts[moment], start=PERIODS[moment][0],
                                 end=PERIODS[moment][1], time_perc=time_diff)
        else:
            perc = 0.15
            dates = _create_date(num=parts[moment], start=PERIODS[moment][0],
                                 end=PERIODS[moment][1], time_perc=0)
        # simulate website URLs
        url = _create_website(num=parts[moment], perc=perc, fake=fake)
        for i in range(parts[moment]):
            # create dictionary per simulated web visit
            results.append({'page_transition': random.choice(TRANSITION),
                            'title': Faker().sentence(),
                            'url': url[i],
                            'client_id': ''.join(
                                random.choices(string.ascii_uppercase
                                               + string.digits, k=10)),
                            'time_usec': dates[i],
                            })
    browser_hist = {"Browser History": results}
    return json.dumps(browser_hist)


if __name__ == "__main__":
    file_data = browserhistory(
        num=1000, site_diff=0.15, time_diff=0.2, seed=0, fake=False)
    takeout_path = create_zip(file_data)
    print(f'Created BrowserHistory.json in {takeout_path}')
