"""Get schema's for faking json data"""
from genson import SchemaBuilder


def get_json_schema(json_data):
    """Get JSON schema fron JSON object
    Args:
        json_data (dict): JSON data to extract schema from
    Returns:
        dict: JSDON schema
    """
    builder = SchemaBuilder()
    builder.add_object(json_data)
    json_schema = builder.to_schema()

    return json_schema


def get_faker_schema(json_schema, custom=None, iterations=None, parent_key=None):
    """ Convert JSON schema to a dict containing field names and data types.
        Default data types are used, unless specified in custom dict.
    Args:
        json_schema (dict): JSON schema
        custom (dict): dictionary with custom names and data types specified
        iterations (dict): dictionary with name and length specified for arrays
        parent_key (str): The name of the key to generate fake data for
    Returns:
        dict: custom schema that can be used as input for faker-schema
    """
    if "type" not in json_schema:
        key = next(iter(json_schema))
        if isinstance(custom, dict) and key in custom:
            value = custom[key]
        else:
            value = get_faker_schema(
                json_schema[key], custom=custom, iterations=iterations, parent_key=key)
        return {key: value}
    if json_schema['type'] == "object":
        value = {}
        for prop, val in json_schema["properties"].items():
            value.update(get_faker_schema({prop: val}, custom=custom, iterations=iterations))
    elif json_schema['type'] == "array":
        if iterations:
            iters = iterations.get(parent_key, 1)
        else:
            iters = 1
        value = [get_faker_schema(
            json_schema['items'], custom=custom, iterations=iterations) for i in range(iters)]
    elif json_schema['type'] == "string":
        value = "pystr"
    elif json_schema['type'] == "number":
        value = "pyfloat"
    elif json_schema['type'] == "integer":
        value = "pyint"
    return value
