# Data Extractor

This is a basic template which can be used to write a data extractor.
The extraction logic should be placed in the `process` function within
`data_extractor/__init__.py`. An example has been provided.

The argument that the `process` function receives is a file-like object.
It can therefore be used with most regular Python libraries. The example
demonstrates this by usage of the `zipfile` module.

This project makes use of [Poetry](https://python-poetry.org/). It makes
creating the required Python Wheel a straight-forward process. Install
Poetry with the following command: `pip install poetry`. 
Then easily install the required python packages with `poetry install`.

The behavior of the `process` function can be verified by running the
tests. The test are located in the `tests` folder. To run the tests
execute: `poetry run pytest`.

To run the extraction code from the browser run:
`python3 -m http.server` from the project root folder (the one with `.git`).
This will start a webserver on: [localhost](http://localhost:8000).

Opening a browser with that URL will initialize the application. After
it has been loaded a file can be selected. The output of the process
function will be displayed after a while (depending on the amount of
processing required and the speed of the machine).

# Examples

## Google Semantic Location History 
In this example, we first create a simulated Google Semantic Location History
(GSLH) data download package (DDP). Subsequently, we extract relevant information
from the simulated DDP.

### Data simulation
Command:

`poetry run python google_semantic_location_history/simulation_gslh.py`

This creates a zipfile with the simulated Google Semantic Location
History data in `tests/data/Location History.zip`.

GSLH data is simulated using the python libraries
[GenSON](<https://pypi.org/project/genson/>),
[Faker](<https://github.com/joke2k/faker>), and
[faker-schema](<https://pypi.org/project/faker-schema/>).

The simulation script first generates a JSON schema from a JSON object using
`GenSON's SchemaBuilder` class. The JSON object is derived from an
example GSLH data package, downloaded from Google Takeout. The GSLH data
package consists of monthly JSON files with information on e.g.
geolocations, addresses and time spend in places and in activity. The
JSON schema describes the format of the JSON files, and can be used to
generate fake data with the same format. This is done by converting the
JSON schema to a custom schema expected by `faker-schema` in the form of
a dictionary, where the keys are field names and the values are the
types of the fields. The values represent available data types in Faker,
packed in so-called providers. `Faker` provides a wide variety of data
types via providers, for example for names, addresses, and geographical
data. This allows us to easily customize the faked data to our
specifications.


### Data extraction
Command:

`poetry run python google_semantic_location_history/main.py`

This extracts and displays the relevant data and summary. It calls the
same `process` function as the web application would. To use the GSLH
data extraction script in the web application, one needs to specify this
in [pyworker.js](../pyworker.js) by changing
 `/data_extractor/data_extractor/__init__.py` into 
 `/data_extractor/google_semantic_location_history/__init__.py`.

## Google Search History
In this example, we first create a simulated Google Search History
(GSH) DDP. Subsequently, we extract relevant information from the simulated DDP.

### Data simulation
Command:

`poetry run python google_search_history/simulation_gsh.py`

This will generate a dummy Google Takeout ZIP file, containing a
simulated BrowserHistory.json file, and stores it in `tests/data/takeout.zip`.

The BrowserHistory.json file mainly describes what 
websites were visited by the user and when. To simulate (news) web
pages, you can either base them on real URLs (see
tests/data/urldata.csv) or create entirely fake ones using
[Faker](<https://github.com/joke2k/faker>). The timestamp of each web
visit is set to be before, during, or after a certain period (in this
case, the Dutch COVID-19 related curfew), and is randomly generated
using the [datetime](<https://docs.python.org/3/library/datetime.html>)
and [random](<https://docs.python.org/3/library/random.html>) libraries.

Note that, even though the script is seeded and will, therefore, always
yield the same outcome, there are various options to adapt the output
depending on your personal (research) goal. These options are: 
- *n*: integer, size of BrowserHistory.json (i.e. number of web visits).
Default=1000, 
- *site_diff*: float, percentage of generated websites that should be 'news' 
sites. Default=0.15, 
- *time_diff*: float, minimal percentage of web searchers that were specifically 
made in the evening during the curfew period. Default=0.20, 
- *seed*: integer, sets seed. Default=0, 
- *fake*: boolean, determines if URLs are based on true URLs (False) or entirely 
fake (True). Default=False

### Data extraction
Command:

`poetry run python google_search_history/main.py`

After running this script, the relevant data (i.e., an overview of the
number of visits of news vs. other websites before, during, and after
the curfew, and the corresponding time of day of the visits) are
extracted from the (simulated) takeout.ZIP and displayed in a dataframe
together with a textual summary. It calls the same `process` function as
the web application would. To use the GSH data extraction script in the
web application, specify this in [pyworker.js](../pyworker.js) by changing
 `/data_extractor/data_extractor/__init__.py` into 
 `/data_extractor/google_search_history/__init__.py`.

