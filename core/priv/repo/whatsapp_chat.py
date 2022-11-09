"""Parser utils.
The main part is extracted from https://github.com/lucasrodes/whatstk.git
"""
__version__ = '0.2.0'

import os
import re
from datetime import datetime
import zipfile
from zipfile import BadZipFile
import pandas as pd
import numpy as np


URL_PATTERN = r"(?i)\b((?:https?://|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)" \
              r"(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|" \
              r"(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'\".,<>?«»“”‘’]))"
LOCATION_PATTERN = r'((L|l)ocation: https?://\S+)|((l|L)ocatie: https?://\S+)|' \
                   r'(.*(l|L)ive locatie gedeeld.*)|(.*(l|L)ive location shared.*)'


ATTACH_FILE_PATTERN = r'(<attached: \S+>)|(<Media (weggelaten|omitted)>)|' \
            r'((afbeelding|GIF|video|image|audio|(s|S)ticker|.*document.*) (weggelaten|omitted))'
FILE_RE = re.compile(r".*.txt$")
HIDDEN_FILE_RE = re.compile(r".*__MACOSX*")


SYSTEM_MESSAGES = ['end-to-end', 'WhatsApp']
hformats = ['%m/%d/%y, %H:%M - %name:', '[%d/%m/%y, %H:%M:%S] %name:', '%d-%m-%y %H:%M - %name:',
            '[%d-%m-%y %H:%M:%S] %name:', '[%m/%d/%y, %H:%M:%S] %name:', '%d/%m/%y, %H:%M – %name:',
            '%d/%m/%y, %H:%M - %name:', '%d.%m.%y, %H:%M – %name:', '%d.%m.%y, %H:%M - %name:',
            '%m.%d.%y, %H:%M - %name:', '%m.%d.%y %H:%M - %name:',
            '[%d/%m/%y, %H:%M:%S %P] %name:', '[%m/%d/%y, %H:%M:%S %P] %name:',
            '[%d.%m.%y, %H:%M:%S] %name:', '[%m/%d/%y %H:%M:%S] %name:',
            '[%m-%d-%y, %H:%M:%S] %name:',
            '[%m-%d-%y %H:%M:%S] %name:', '%m-%d-%y %H:%M - %name:', '%m-%d-%y, %H:%M - %name:',
            '%m-%d-%y, %H:%M , %name:', '%m/%d/%y, %H:%M , %name:', '%d-%m-%y, %H:%M , %name:',
            '%d/%m/%y, %H:%M , %name:', '%d.%m.%y %H:%M – %name:', '%m.%d.%y, %H:%M – %name:',
            '%m.%d.%y %H:%M – %name:', '[%d.%m.%y %H:%M:%S] %name:', '[%m.%d.%y, %H:%M:%S] %name:',
            '[%m.%d.%y %H:%M:%S] %name:']


class ColnamesDf:  # pylint: disable=R0903
    """Access class constants using variable ``COLNAMES_DF``."""

    DATE = 'date'
    """Date column"""

    USERNAME = 'username'
    """Username column"""

    MESSAGE = 'message'
    """Message column"""

    MESSAGE_LENGTH = 'Lengte bericht'
    """Message length column"""

    FirstMessage = 'Datum eerste bericht'
    """Date of first message column"""

    LastMessage = 'Datum laatste bericht'
    """Date of last message column"""

    MESSAGE_NO = 'Aantal berichten'
    """Number of Message  column"""

    WORDS_NO = 'Aantal woorden'
    """Total number of words  column"""

    REPLY_2USER = 'Wie reageert het meest op u?'
    """Who replies to the user the most column"""

    USER_REPLY2 = 'Op wie reageert u het meest?'
    """User replies to who the most column"""

    URL_NO = 'Aantal websites'
    """Number of URLs column"""

    LOCATION_NO = 'Aantal locaties'
    """Number of locations column"""

    FILE_NO = 'Aantal foto’s en bestanden'
    """Number of files column"""

    EMOJI_NO = 'emoji_no'
    """Total number of emojies column"""

    EMOJI_Fav = 'emoji_fav'
    """Favorite emojies column"""

    DESCRIPTION = 'Omschrijving'
    """Variable column in melted dataframe"""

    VALUE = 'Gegevens'
    """Value column in melted dataframe"""


COLNAMES_DF = ColnamesDf()


class DutchConst:  # pylint: disable=R0903
    """Access class constants using variable ``DUTCH_CONST``."""

    YOU = 'u'
    """Refer to the data donor in dutch"""
    PRE_MESSAGE = 'Wij ontvingen de volgende waarschuwing: '
    POST_MESSAGE = 'Dit is voor ons nog steeds waardevolle informatie' \
                   ' en u kunt dit resultaat ook doneren.'


DUTCH_CONST = DutchConst()

# *** parsing functions ***
regex_simplifier = {
    '%Y': r'(?P<year>\d{2,4})',
    '%y': r'(?P<year>\d{2,4})',
    '%m': r'(?P<month>\d{1,2})',
    '%d': r'(?P<day>\d{1,2})',
    '%H': r'(?P<hour>\d{1,2})',
    '%I': r'(?P<hour>\d{1,2})',
    '%M': r'(?P<minutes>\d{2})',
    '%S': r'(?P<seconds>\d{2})',
    '%P': r'(?P<ampm>[AaPp].? ?[Mm].?)',
    '%p': r'(?P<ampm>[AaPp].? ?[Mm].?)',
    '%name': fr'(?P<{COLNAMES_DF.USERNAME}>[^:]*)'
}


def generate_regex(log_error, hformat):
    r"""Generate regular expression from hformat.
    Parameters
    ----------
    log_error : list
        List of error messages
    hformat :str
        Simplified syntax for the header, e.g. ``'%y-%m-%d, %H:%M:%S - %name:'``.
    Returns
    -------
    str
        Regular expression corresponding to the specified syntax
    """
    items = re.findall(r'\%\w*', hformat)

    for i in items:
        try:
            hformat = hformat.replace(i, regex_simplifier[i])
        except KeyError:
            log_error(f"Could find regular expression for : {i}")

    hformat = hformat + ' '
    hformat_x = hformat.split('(?P<username>[^:]*)')[0]
    return hformat, hformat_x


def add_schema(df_chat):
    """Add default chat schema to df.
    Parameters
    ----------
    df_chat : pandas.DataFrame
        Chat DataFrame.
    Returns
    -------
    pandas.DataFrame
        Chat DataFrame with correct dtypes
    """
    df_chat = df_chat.astype({
        COLNAMES_DF.DATE: pd.StringDtype(),
        COLNAMES_DF.USERNAME: pd.StringDtype(),
        COLNAMES_DF.MESSAGE: pd.StringDtype()
    })
    return df_chat


def parse_line(text, headers, i):
    """Get date, username and message from the i:th intervention.
    Parameters
    ----------
    text : str
        Whole log chat text
    headers : list
        All headers.
    i : int
        Index denoting the message number
    Returns
    -------
    dict
        ith date, username and message.
    """
    result_ = headers[i].groupdict()
    if 'ampm' in result_:
        hour = int(result_['hour'])
        mode = result_.get('ampm').lower()
        if hour == 12 and mode == 'am':
            hour = 0
        elif hour != 12 and mode == 'pm':
            hour += 12
    else:
        hour = int(result_['hour'])

    # Check format of year. If year is 2-digit represented we add 2000
    if len(result_['year']) == 2:
        year = int(result_['year']) + 2000
    else:
        year = int(result_['year'])

    if 'seconds' not in result_:
        date = datetime(year, int(result_['month']), int(result_['day']), hour,
                        int(result_['minutes']))
    else:
        date = datetime(year, int(result_['month']), int(result_['day']), hour,
                        int(result_['minutes']), int(result_['seconds']))
    username = result_[COLNAMES_DF.USERNAME]
    message = get_message(text, headers, i)
    line_dict = {
        COLNAMES_DF.DATE: date,
        COLNAMES_DF.USERNAME: username,
        COLNAMES_DF.MESSAGE: message
    }
    return line_dict


def remove_alerts_from_df(r_x, df_chat):
    """Try to get rid of alert/notification messages.
    Parameters
    ----------
    r_x : str
        Regular expression to detect whatsapp warnings
    df_chat : pandas.DataFrame
        pandas.DataFrame with all interventions
    Returns
    -------
    pandas.DataFrame
        Fixed version of input DataFrame
    """

    alerts_no = count_alerts(r_x, df_chat)
    df_new = df_chat.copy()
    df_new.loc[:, COLNAMES_DF.MESSAGE] = df_new[COLNAMES_DF.MESSAGE].apply(
        lambda x: remove_alerts_from_line(r_x, x))
    return df_new, alerts_no


def remove_alerts_from_line(r_x, line_df):
    """Remove line content that is not desirable (automatic alerts etc.).
    Parameters
    ----------
    r_x : str
        Regula expression to detect WhatsApp warnings
    line_df : str
        Message sent as string
    Returns
    -------
    str
        Cleaned message string
    """
    if re.search(r_x, line_df):
        return line_df[:re.search(r_x, line_df).start()]

    return line_df


def count_alerts(r_x, df_chat):
    """Count line content that is not desirable (automatic alerts etc.).
    Parameters
    ----------
    r_x : str
        Regula expression to detect WhatsApp warnings
    df_chat : pandas.DataFrame
        pandas.DataFrame with all interventions

    Returns
    -------
    int
        Number of line contents that is not desirable
    """

    # alerts_count = df[COLNAMES_DF.MESSAGE].apply(lambda x: (re.search(r_x, x) is not None))
    alerts_count = df_chat[COLNAMES_DF.MESSAGE].apply(lambda x: re.findall(r_x, x))
    return alerts_count.str.len().sum()


def get_message(text, headers, i):
    """Get i:th message from text.
    Parameters
    ----------
        text : str
            Whole log chat text
    headers : list
        All headers
    i : int
        Index denoting the message number
    Returns
    -------
    str
     ith message.
    """
    msg_start = headers[i].end()
    msg_end = headers[i + 1].start() if i < len(headers) - 1 else headers[i].endpos
    msg = text[msg_start:msg_end].strip()
    return msg


def parse_text(text, regex):
    """Parse chat using given regex.
    Parameters
    ----------
    text : str
        Whole log chat text
    regex : str
        Regular expression
    Returns
    -------
    pandas.DataFrame
        pandas.DataFrame with messages sent by users

    Raises
    ------
    RegexError
        When provided regex could not match the text
    """
    result = []
    headers = list(re.finditer(regex, text))
    try:
        for i in range(len(headers)):
            line_dict = parse_line(text, headers, i)
            result.append(line_dict)
    except KeyError:
        print("Could not match the provided regex with provided text. No match was found.")
        return None

    df_chat = pd.DataFrame.from_records(result)
    df_chat = df_chat[[COLNAMES_DF.DATE, COLNAMES_DF.USERNAME, COLNAMES_DF.MESSAGE]]

    # clean username
    df_chat[COLNAMES_DF.USERNAME] = df_chat[COLNAMES_DF.USERNAME].apply(lambda u: u.strip('\u202c'))

    return df_chat


def make_df_general_regx(log_error, text):
    """Use a general regex to load chat as a DataFrame.
        Parameters
        ----------
        log_error : list
            List of error messages
        text : str
            Text of the chat

        Returns
        -------
        pandas.DataFrame
            pandas.DataFrame with messages sent by users

        """

    expr_to_test = re.compile(r"^(.*?)(?:\] | - )(.*?): (.*?$)", flags=re.DOTALL)
    lines = text.split("\n")
    result = []
    line_counts = len(lines)
    for line in lines:
        try:

            res = expr_to_test.match(line)

            timestamp = res.group(1)
            username = res.group(2)
            message = res.group(3)

            # clean timestamp
            timestamp = timestamp.replace('[', '').replace(',', '')
            timestamp = timestamp.strip('\u202c')
            timestamp = timestamp.strip('\u200e')

            timestamp = pd.to_datetime(timestamp)

            line_dict = {
                COLNAMES_DF.DATE: timestamp,
                COLNAMES_DF.USERNAME: username,
                COLNAMES_DF.MESSAGE: message
            }

            result.append(line_dict)
        except AttributeError:
            pass

    if len(result) == 0:
        log_error("Failed to read the Chat file.")
        return None
    df_chat = pd.DataFrame.from_records(result)
    df_chat = df_chat[[COLNAMES_DF.DATE, COLNAMES_DF.USERNAME, COLNAMES_DF.MESSAGE]]

    # clean username
    df_chat[COLNAMES_DF.USERNAME] = df_chat[COLNAMES_DF.USERNAME].apply(
        lambda u: u.strip('\u202c'))

    # log unprocessed_line_no= the number of lines in multiline messages +
    # the number of system messages
    unprocessed_line_no = line_counts - df_chat.shape[0]

    if unprocessed_line_no > 0:
        log_error("Number of unprocessed lines: " + str(unprocessed_line_no))

    return df_chat


def make_chat_df(log_error, text, hformat):
    """Load chat as a DataFrame.
    Parameters
    ----------
    log_error : list
        List of error messages
    text : str
        Text of the chat
    hformat : str
        Simplified syntax for the header, e.g. ``'%y-%m-%d, %H:%M:%S - %name:'``

    Returns
    -------
    pandas.DataFrame
        A pandas.DataFrame with three columns, i.e. 'date', 'username', and 'message'
    """
    # Bracket is reserved character in RegEx, add backslash before them.
    hformat = hformat.replace('[', r'\[').replace(']', r'\]')

    # Generate regex for given hformat
    reg, r_x = generate_regex(log_error, hformat=hformat)

    # Parse chat to DataFrame
    try:
        df_chat = parse_text(text, reg)
        df_chat, alerts_no = remove_alerts_from_df(r_x, df_chat)
        df_chat = add_schema(df_chat)

        if alerts_no > 0:
            log_error("Number of unprocessed system messages: " + str(alerts_no))

        return df_chat
    except (KeyError, AttributeError, ValueError):
        print(f"hformat : {hformat} is not match with the given text")
        return None


def parse_chat(log_error, data):
    """Parse chat and test it with defined hformats.
    Parameters
    ----------
    log_error : list
       List of error messages.
    data : str
        Data read from the chat file
    Returns
    -------
    pandas.dataframe
        A pandas.DataFrame with three columns, i.e. 'date', 'username', and 'message'
    """
    for hformat in hformats:
        # Build DataFrame
        df_chat = make_chat_df(log_error, data, hformat)
        if df_chat is not None:
            return df_chat
    log_error("hformats did not match the provided text. We try to use a general regex"
              " to read the chat file. ")
    # If header format is unknown to our script we use a loose regular expression to detect
    df_chat = make_df_general_regx(log_error, data)
    # if df_chat.shape[0] > 0:
    #     return df_chat
    # log_error("Failed to read the Chat file.")
    # return None
    return df_chat


def decode_chat(log_error, file_chat, filename):
    """Parse the given zip file.
    Parameters
    ----------
    log_error : list
        List of error messages.
    f : bytes
        bytes of the file name in the zip file
    filename : str
        Name of a compressed file in the zip file.
    Returns
    -------
    pandas.DataFrame
        A pandas.DataFrame which includes the content of the given chat file.
    """
    try:
        data = file_chat.decode("utf-8")
    except UnicodeEncodeError:
        log_error(f"Could not decode to utf-8: {filename}")
        return None
    else:
        return parse_chat(log_error, data)


def parse_zipfile(log_error, zfile):
    """Parse the given zip file.
    Parameters
    ----------
    log_error : list
        List of error messages
    zfile : ZipFile object
        Regular expression
    Returns
    -------
    pandas.DataFrame
        A pandas.DataFrames which include the content of the chat file.
    """
    for name in zfile.namelist():
        if HIDDEN_FILE_RE.match(name):
            continue
        if not FILE_RE.match(name):
            continue
        chat = decode_chat(log_error, zfile.read(name), name)

    if chat is None:
        log_error("No valid chat file is available")

    return chat

# *** test related function ***


def input_df(data_path):
    """Create inputs df_chats and df_participants, used for test purposes.
    Parameters
    ----------
    data_path : str
        File path of zip file
    Returns
    -------
    pandas.DataFrame
        df_chats and df_participants
    """
    errors = []
    log_error = errors.append
    username = 'Deelnemer 1'
    fp_chat = os.path.join(data_path, "whatsapp_chat.zip")
    chat_df = parse_chat_file(log_error, str(fp_chat))
    if chat_df is not None:
        chat_df = remove_system_messages(chat_df)
        participants_df = get_participants_features(chat_df)
        results = extract_results(participants_df, username, anonymize=False)
        return chat_df, results
    return None

# *** analysis functions ***


def get_response_matrix(df_chat):
    """Create a response matrix for the usernames mentioned in the given DataFrame.
    Parameters
    ----------
    df_chat: padas.DataFrame
        A DataFrame including chat data
    Returns
    -------
    pandas.DataFrame
        A DataFrame with senders in the rows and receivers in the columns
    """
    users = set(df_chat[COLNAMES_DF.USERNAME])
    users = sorted(users)

    # Get list of username transitions and initialize dicitonary with counts
    user_transitions = df_chat[COLNAMES_DF.USERNAME].tolist()
    responses = {user: dict(zip(users, [0] * len(users))) for user in users}
    # Fill count dictionary
    for i in range(1, len(user_transitions)):
        sender = user_transitions[i]
        receiver = user_transitions[i - 1]
        if sender != receiver:
            responses[sender][receiver] += 1

    responses = pd.DataFrame.from_dict(responses, orient='index')
    return responses


# def make_salt():
#     """Return an string as salt for anonym_txt function.
#     Returns
#     -------
#     str
#         The salt value is deliberately set to be a fixed value for all the usernames,
#         because then we can generate the
#         same hashed value for the same value in the UERNAME, REPLY_2USER, and USER_REPLY2 columns.
#     """
#     return str.encode('WhatsAppProject@2022')


def anonymize_participants(df_participants, donor_user_name):
    """Anonymize text data.
    Anonymize USERNAME, REPLY_2USER, and USER_REPLY2 columns of the given DataFrame.
    Parameters
    ----------
    df_participants : pandas.DataFrame
        A DataFrame including participants data
    Returns
    -------
    pandas.DataFrame
        An anonymized DataFrame
    """
    # salt = make_salt()
    # df_participants[COLNAMES_DF.USERNAME] = df_participants[COLNAMES_DF.USERNAME].apply(
    # lambda u: anonym_txt(u, salt))
    # df_participants[COLNAMES_DF.REPLY_2USER] = df_participants
    # [COLNAMES_DF.REPLY_2USER].apply(lambda u:
    # anonym_txt(u,salt))
    # df_participants[COLNAMES_DF.USER_REPLY2] = df_participants[COLNAMES_DF.USER_REPLY2].
    # apply(lambda u:
    # anonym_txt(u,salt))
    # df_participants[['username', 'user_reply2']] = df_participants[['username',
    # 'user_reply2']].stack().rank(
    # method='dense').unstack()

    stacked = df_participants[[COLNAMES_DF.USERNAME,
                               COLNAMES_DF.USER_REPLY2,
                               COLNAMES_DF.REPLY_2USER]].stack()
    df_participants[[COLNAMES_DF.USERNAME,
                     COLNAMES_DF.USER_REPLY2,
                     COLNAMES_DF.REPLY_2USER]] = \
        pd.Series(stacked.factorize()[0], index=stacked.index).unstack()
    df_participants[[COLNAMES_DF.USERNAME,
                     COLNAMES_DF.USER_REPLY2,
                     COLNAMES_DF.REPLY_2USER]] = \
        'Deelnemer ' + df_participants[[COLNAMES_DF.USERNAME,
                                        COLNAMES_DF.USER_REPLY2,
                                        COLNAMES_DF.REPLY_2USER]].astype(str)

    # replace donor_user_name with word 'you'
    fact_index_bool = (stacked.factorize()[1] == donor_user_name)
    you_index = np.where(fact_index_bool)[0][0]
    you_username = 'Deelnemer ' + str(you_index)

    df_participants[[COLNAMES_DF.USERNAME,
                     COLNAMES_DF.USER_REPLY2,
                     COLNAMES_DF.REPLY_2USER]] = \
        df_participants[[COLNAMES_DF.USERNAME,
                         COLNAMES_DF.USER_REPLY2,
                         COLNAMES_DF.REPLY_2USER]].replace(you_username, DUTCH_CONST.YOU)

    return df_participants


def get_wide_to_long_participant(df_participants):
    """Generate one dataframe for each participant .
        Parameter
        ----------
        df_participants : pandas.DataFrame
           A DataFrame which includes participants and their features

        anonymize : bool
            Indicates if usernames should be anonymized
        Returns
        -------
        list pandas.DataFrame
            A list of pandas.DataFrame. Each data frame includes the description of features and
            their values extracted from a specific participant
        """
    results = []
    df_melt = pd.melt(df_participants, id_vars=[COLNAMES_DF.USERNAME],
                      value_vars=[COLNAMES_DF.WORDS_NO,
                                  COLNAMES_DF.MESSAGE_NO,
                                  COLNAMES_DF.FirstMessage,
                                  COLNAMES_DF.LastMessage,
                                  COLNAMES_DF.URL_NO,
                                  COLNAMES_DF.FILE_NO,
                                  COLNAMES_DF.LOCATION_NO,
                                  COLNAMES_DF.REPLY_2USER,
                                  COLNAMES_DF.USER_REPLY2],
                      var_name=COLNAMES_DF.DESCRIPTION, value_name=COLNAMES_DF.VALUE)

    usernames = sorted(set(df_melt[COLNAMES_DF.USERNAME]))

    # bring donator username to the top of the list
    usernames.insert(0, usernames.pop(usernames.index(DUTCH_CONST.YOU)))

    for user_name in usernames:
        df_user = df_melt[(df_melt[COLNAMES_DF.USERNAME] == user_name) &
                          df_melt[COLNAMES_DF.VALUE] != 0]

        results.append(df_user)

    return results


def get_participants_features(df_chat):
    """Calculate participant features from the given chat.
    Parameter
    ----------
    df_chat : pandas.DataFrame
        A DataFrame including chat data
    Returns
    -------
    pandas.DataFrame
        A DataFrame which includes participants and their features
    """
    # Calculate first message date
    df_chat[COLNAMES_DF.FirstMessage] = df_chat[COLNAMES_DF.DATE].astype('datetime64[ns]')
    df_chat[COLNAMES_DF.FirstMessage] = df_chat[COLNAMES_DF.FirstMessage].dt.floor('Min')
    # Calculate last message date
    df_chat[COLNAMES_DF.LastMessage] = df_chat[COLNAMES_DF.DATE].astype('datetime64[ns]')
    df_chat[COLNAMES_DF.LastMessage] = df_chat[COLNAMES_DF.LastMessage].dt.floor('Min')
    # Calculate the number of words in messages
    df_chat[COLNAMES_DF.WORDS_NO] = df_chat['message'].apply(lambda x: len(x.split()))
    # number of ulrs
    df_chat[COLNAMES_DF.URL_NO] = df_chat["message"].apply(
        lambda x: len(re.findall(URL_PATTERN, x))).astype(int)
    # number of locations
    df_chat[COLNAMES_DF.LOCATION_NO] = df_chat["message"].apply(
        lambda x: len(re.findall(LOCATION_PATTERN, x))).astype(int)
    # number of files
    df_chat[COLNAMES_DF.FILE_NO] = df_chat["message"].apply(
        lambda x: len(re.findall(ATTACH_FILE_PATTERN, x))).astype(
        int)
    # number of messages
    df_chat[COLNAMES_DF.MESSAGE_NO] = 1

    df_participants = df_chat.groupby(COLNAMES_DF.USERNAME).agg({
        COLNAMES_DF.WORDS_NO: 'sum',
        COLNAMES_DF.URL_NO: 'sum',
        COLNAMES_DF.LOCATION_NO: 'sum',
        COLNAMES_DF.FILE_NO: 'sum',
        COLNAMES_DF.MESSAGE_NO: 'sum',
        COLNAMES_DF.FirstMessage: 'min',
        COLNAMES_DF.LastMessage: 'max'
    }).reset_index()

    response_matrix = get_response_matrix(df_chat)
    user_reply2 = response_matrix.idxmax(axis=1)
    reply2_user = response_matrix.T.idxmax(axis=1)

    response_matrix[COLNAMES_DF.USER_REPLY2] = user_reply2
    response_matrix[COLNAMES_DF.REPLY_2USER] = reply2_user
    response_matrix.index.name = COLNAMES_DF.USERNAME
    response_matrix = response_matrix.loc[:, [COLNAMES_DF.USER_REPLY2, COLNAMES_DF.REPLY_2USER]]
    response_matrix = response_matrix.reset_index()

    df_participants = pd.merge(df_participants, response_matrix, how="left",
                               on=COLNAMES_DF.USERNAME, validate="1:1")

    return df_participants


def remove_system_messages(chat):
    """Removes system messages from chat
    Parameters
    ----------
    chat : pandas.DataFrame
        A DataFrame that includes chat data
    Returns
    -------
    pandas.DataFrame
        A filtered dataframe
    """

    message0 = chat.loc[0, COLNAMES_DF.MESSAGE]
    is_system_message = bool(all(s in message0 for s in SYSTEM_MESSAGES))
    if is_system_message:
        group_name = chat.loc[0, COLNAMES_DF.USERNAME]
        chat = chat.loc[chat[COLNAMES_DF.USERNAME] != group_name, ]

    return chat


def extract_results(participants_df, donor_user_name, anonymize=True):
    """Parse the given zip file.
    Parameters
    ----------
    participants_df : pandas.DataFrame
        A DataFrame that includes participants data
    donor_user_name : str

    anonymize : bool
        Indicates if usernames should be anonymized
    Returns
    -------
    list
        A list of DataFrames which include participant features
    """
    if anonymize:
        participants_df = anonymize_participants(participants_df, donor_user_name)

    results = get_wide_to_long_participant(participants_df)
    return results

# ***** end of analysis functions *****


def format_results(df_list, error):
    """Format results to the standard format.
    Parameters
    ----------
    df_list: pandas.dataframe
    Returns
    -------
    pandas.dataframe
    """
    results = []
    for df_item in df_list:
        user_name = pd.unique(df_item[COLNAMES_DF.USERNAME])[0]
        results.append(
            {
                "id": user_name,
                "title": user_name,
                "data_frame": df_item[[COLNAMES_DF.DESCRIPTION, COLNAMES_DF.VALUE]].reset_index(
                    drop=True)
            }
        )
    if len(error) > 0:
        results = results+error
    return {"cmd": "result", "result": results}


def format_errors(errors):
    """Return errors in the format of dataframe.
    Parameters
    ----------
    errors: str
    Returns
    -------
    pandas.dataframe
    """
    if len(errors) == 0:
        return []
    data_frame = pd.DataFrame()
    data_frame[COLNAMES_DF.DESCRIPTION] = pd.Series(errors, name=COLNAMES_DF.DESCRIPTION)
    return [{"id": "extraction_log", "title": DUTCH_CONST.PRE_MESSAGE, "data_frame": data_frame}]


def parse_chat_file(log_error, chat_file_name):
    """Read whatsapp chat file and return chat data in the format of a dataframe.
    Parameters
    ----------
    chat_file_name : str
        The path of the chat file. It can be in zip or txt format.
    log_error : list
       List of error messages.
    Returns
    -------
    pandas.dataframe
        Extracted data from the chat file
    """

    try:
        zfile = zipfile.ZipFile(chat_file_name)  # pylint: disable=R1732

    except BadZipFile:

        if FILE_RE.match(chat_file_name):
            with open(chat_file_name, encoding="utf8") as tfile:
                chat = parse_chat(log_error, tfile.read())

        else:
            log_error("There is not a valid input file format.")
            return None
    else:
        chat = parse_zipfile(log_error, zfile)

    return chat


def process():
    """Convert whatsapp chat file to participant dataframes.
       This is the main function which extracts the participants
       information from the row chat file provided by data-donors.
       Parameters
       ----------
       chat_file_name : str
           The path of the chat file. It can be in zip or txt format.
       Returns
       -------
       pandas.dataframe
           Extracted data from the chat file
       """
    errors = []
    log_error = errors.append

    chat_file_name = yield prompt_file()
    chat_df = parse_chat_file(log_error, chat_file_name)
    if chat_df is not None:
        chat_df = remove_system_messages(chat_df)
        participants_df = get_participants_features(chat_df)
        usernames = extract_usernames(participants_df)
        username = yield prompt_radio(usernames)
        results = extract_results(participants_df, username)
        yield format_results(results, format_errors(errors))
    else:
        yield format_results([], format_errors(errors))


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
                    "en": "Step 1: Select the chat file",
                    "nl": "Stap 1: Selecteer het chat file"
                },
                "description": {
                    "en": "We previously asked you to export a chat file from Whatsapp. "
                          "Please select this file so we can extract relevant information "
                          "for our research.",
                    "nl": "We hebben u gevraagd een chat bestand te exporteren uit Whatsapp. "
                          "U kunt dit bestand nu selecteren zodat wij er relevante informatie uit"
                          " kunnen halen voor ons onderzoek."
                },
                "extensions": "application/zip, text/plain",
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


def extract_usernames(participants_df):
    """Extract username from the given dataframe.
           This function is used by Eyra system to show the list of extracted usernames
           to the donor.
           Parameters
           ----------
           participants_df: pandas.dataframe
               Participants in the chat and their features
           Returns
           -------
           pandas.Series
               Extracted usernames
    """
    return participants_df[COLNAMES_DF.USERNAME].tolist()  # pylint: disable=C0302
