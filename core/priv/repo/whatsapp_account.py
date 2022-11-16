# pylint: disable=R0801
"""Parse account_info"""
__version__ = '0.2.0'

import zipfile
import re
import json
import pandas as pd


HIDDEN_FILE_RE = re.compile(r".*__MACOSX*")
FILE_RE = re.compile(r".*.json$")


class ColnamesDf:  # pylint: disable=R0903
    """Class to define column names"""
    GROUPS = 'wa_groups'
    """Groups column"""

    CONTACTS = 'wa_contacts'
    """Contacts column"""

    GROUPS_OLD = 'groups'
    """Groups column"""

    CONTACTS_OLD = 'contacts'
    """Contacts column"""

    GROUPS_OUTPUT = 'Aantal groepen'
    """Groups column"""

    CONTACTS_OUTPUT = 'Aantal contacten'
    """Contacts column"""


COLNAMES_DF = ColnamesDf()


class DutchConst:  # pylint: disable=R0903
    """Access class constants using variable ``DUTCH_CONST``."""

    LOG_TITLE = 'Wij ontvingen de volgende waarschuwing: '
    OUTPUT_TITLE = "Het account informatie bestand bestaat uit:"
    DESCRIPTION = "Omschrijving"


DUTCH_CONST = DutchConst()


def format_results(dataframe, error):
    """Format results to the standard format.
    Parameters
    ----------
    dataframe: pandas.dataframe
    error : list
    Returns
    -------
    pandas.dataframe
    """

    results = []
    results.append(
        {
            "id": "Whatsapp account info",
            "title": DUTCH_CONST.OUTPUT_TITLE,
            "data_frame": dataframe
        }
    )
    if len(error) > 0:
        results = results+error
    return {"cmd": "result", "result": results}


def format_errors(errors):
    """Return errors in the format of dataframe.
    Parameters
    ----------
    errors: list
    Returns
    -------
    pandas.dataframe
    """
    if len(errors) == 0:
        return []
    data_frame = pd.DataFrame()
    data_frame[DUTCH_CONST.DESCRIPTION] = pd.Series(errors, name=DUTCH_CONST.DESCRIPTION)
    return [{"id": "extraction_log", "title": DUTCH_CONST.LOG_TITLE, "data_frame": data_frame}]


def extract_groups(log_error, data):
    """Function for extracting the number of groups"""

    groups_no = 0
    try:
        groups_no = len(data[COLNAMES_DF.GROUPS])
    except (TypeError, KeyError):
        print("No group is available")

    if groups_no == 0:
        log_error("No group is available")

    return groups_no


def extract_contacts(log_error, data):
    """Function for extracting the number of contacts"""

    contacts_no = 0

    try:
        contacts_no = len(data[COLNAMES_DF.CONTACTS])
    except (TypeError, KeyError):
        print("No contact is available")

    if contacts_no == 0:
        log_error("No contact is available")
    return contacts_no


def extract_data(log_error, data):
    """Function to extract group_no and contact_no fields - Support for the old format"""
    groups_no = 0
    contacts_no = 0
    try:
        groups_no = len(data[COLNAMES_DF.GROUPS_OLD])
    except (TypeError, KeyError):
        print("No group is available")
    try:
        contacts_no = len(data[COLNAMES_DF.CONTACTS_OLD])
    except (TypeError, KeyError):
        print("No contact is available")

    if (groups_no == 0) and (contacts_no == 0):
        log_error("Neither group nor contact is available")
    return groups_no, contacts_no


def parse_records(log_error, file):  # pylint: disable=R1710
    """Function for loading json files content"""
    try:
        data = json.load(file)
    except json.JSONDecodeError:
        log_error(f"Could not parse: {file.name}")
    else:
        return data


def parse_zipfile(log_error, zfile):
    """Function for extracting input zipfile"""
    for name in zfile.namelist():
        if name == 'whatsapp_connections/groups.json':
            if HIDDEN_FILE_RE.match(name):
                continue
            if not FILE_RE.match(name):
                continue
            data_groups = parse_records(log_error, zfile.open(name))
        elif name == 'whatsapp_connections/contacts.json':
            if HIDDEN_FILE_RE.match(name):
                continue
            if not FILE_RE.match(name):
                continue
            data_contacts = parse_records(log_error, zfile.open(name))
    # log_error("No Json file is available")
    return data_groups, data_contacts


def parse_zipfile_old_format(log_error, zfile):
    """Function for extracting input zipfile"""
    for name in zfile.namelist():
        if HIDDEN_FILE_RE.match(name):
            continue
        if not FILE_RE.match(name):
            continue
        return parse_records(log_error, zfile.open(name))
    log_error("No Json file is available")


def prompt_file():
    """Promt a file selection window in Eyra system
                   Parameters
                   ----------

                   Returns
                   -------
                   Dictionary
                       a prompt event - file type
    """
    return {
        "cmd": "prompt",
        "prompt": {
            "type": "file",
            "file": {
                "title": {
                    "en": "Step 1: Select the account info file",
                    "nl": "Stap 1: Selecteer het account info file"
                },
                "description": {
                    "en": "We previously asked you to export an acount info file from Whatsapp. "
                          "Please select this file so we can extract relevant information "
                          "for our research.",
                    "nl": "We hebben u gevraagd een account info bestand te exporteren uit "
                          "Whatsapp. U kunt dit bestand nu selecteren zodat wij er relevante "
                          " informatie uit kunnen halen voor ons onderzoek."
                },
                "extensions": "application/zip",
            }
        }
    }


def prompt_radio(usernames):
    """Promt a list of items(usernames here) in Eyra system
               This function shows a list of radio-buttons
               Parameters
               ----------
               usernames: pandas.Series
                   Extracted usernames from the chat file
               Returns
               -------
               Dictionary
                   a prompt event - radio type
    """
    return {
        "cmd": "prompt",
        "prompt": {
            "type": "radio",
            "radio": {
                "title": {
                    "en": "Step 2: Select your username",
                    "nl": "Stap 2: Selecteer je gebruikersnaam"
                },
                "description": {
                    "en": "The following users are extracted from the chat file. "
                          "Which one are you?",
                    "nl": "Geef hieronder aan welke gebruikersnaam van u is. "
                          "Deze data wordt niet opgeslagen, maar alleen gebruikt om de juiste "
                          "informatie uit uw data te kunnen halen."

                },
                "items": usernames,
            }
        }
    }


def process():
    """Main function for extracting account information"""
    errors = []
    log_error = errors.append

    file_data = yield prompt_file()
    zfile = zipfile.ZipFile(file_data)  # pylint: disable=R1732
    try:

        data_groups, data_contacts = parse_zipfile(log_error, zfile)

        if data_groups is not None:
            groups_no = extract_groups(log_error, data_groups)

        if data_contacts is not None:
            contacts_no = extract_contacts(log_error, data_contacts)

        if errors:
            yield format_results([], format_errors(errors))

    # Support old format of the account_info data package
    except UnboundLocalError:
        data = parse_zipfile_old_format(log_error, zfile)
        if data is not None:
            groups_no, contacts_no = extract_data(log_error, data)

        if errors:
            yield format_results([], format_errors(errors))

    data_info = {COLNAMES_DF.GROUPS_OUTPUT: [groups_no], COLNAMES_DF.CONTACTS_OUTPUT: [contacts_no]}
    results = pd.DataFrame(data=data_info)
    yield format_results(results, format_errors(errors))
