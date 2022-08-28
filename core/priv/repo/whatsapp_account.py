__version__ = '0.2.0'

import zipfile
import re
import json
import pandas as pd

HIDDEN_FILE_RE = re.compile(r".*__MACOSX*")
FILE_RE = re.compile(r".*.json$")


class ColnamesDf:
    GROUPS = 'wa_groups'
    """Groups column"""

    CONTACTS = 'wa_contacts'
    """Contacts column"""


COLNAMES_DF = ColnamesDf()


def format_results(df):
    """Function for formatting results to the Eyra's standard format"""
    results = []
    results.append(
        {
            "id": "Whatsapp account info",
            "title": "The account information file is read:",
            "data_frame": df
        }
    )
    return results


def format_errors(errors):
    """ Function for formatting logging messages as a dataframe """
    data_frame = pd.DataFrame()
    data_frame["Messages"] = pd.Series(errors, name="Messages")
    return {"id": "extraction_log", "title": "Extraction log", "data_frame": data_frame}


def extract_groups(log_error, data):
    """Function for extracting the number of groups"""

    groups_no = 0
    try:
        groups_no = len(data[COLNAMES_DF.GROUPS])
    except (TypeError, KeyError) as e:
        print("No group is available")

    if groups_no == 0:
        log_error("No group is available")

    return groups_no


def extract_contacts(log_error, data):
    """Function for extracting the number of contacts"""

    contacts_no = 0

    try:
        contacts_no = len(data[COLNAMES_DF.CONTACTS])
    except (TypeError, KeyError) as e:
        print("No contact is available")

    if contacts_no == 0:
        log_error("No contact is available")
    return contacts_no


def extract_data(log_error, data):
    """Function to extract group_no and contact_no fields - Support for the old format"""
    groups_no = 0
    contacts_no = 0
    try:
        groups_no = len(data[COLNAMES_DF.GROUPS])
    except (TypeError, KeyError) as e:
        print("No group is available")
    try:
        contacts_no = len(data[COLNAMES_DF.CONTACTS])
    except (TypeError, KeyError) as e:
        print("No contact is available")

    if (groups_no == 0) and (contacts_no == 0):
        log_error("Neither group nor contact is available")
    return groups_no, contacts_no


def parse_records(log_error, f):
    """Function for loading json files content"""
    try:
        data = json.load(f)
    except json.JSONDecodeError:
        log_error(f"Could not parse: {f.name}")
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


def process(file_data):
    """Main function for extracting account information"""
    errors = []
    log_error = errors.append
    zfile = zipfile.ZipFile(file_data)
    try:
        data_groups, data_contacts = parse_zipfile(log_error, zfile)

        if data_groups is not None:
            groups_no = extract_groups(log_error, data_groups)

        if data_contacts is not None:
            contacts_no = extract_contacts(log_error, data_contacts)

        if errors:
            return [format_errors(errors)]

    except:  # Support old format of the account_info data package
        COLNAMES_DF.GROUPS = 'groups'
        COLNAMES_DF.CONTACTS = 'contacts'
        data = parse_zipfile_old_format(log_error, zfile)
        if data is not None:
            groups_no, contacts_no = extract_data(log_error, data)

        if errors:
            return [format_errors(errors)]

    data_info = {'number_of_groups': [groups_no], 'number_of_contacts': [contacts_no]}
    df_info = pd.DataFrame(data=data_info)
    formatted_results = format_results(df_info)

    return formatted_results
