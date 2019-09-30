import requests
import json

from requests.exceptions import HTTPError
from python_helpers.pretty_print import print_error


#
# create a rest call, with two optional variables, auth_token for before you can retrieve it, and
# get if this needs to be a GET call instead of POST
#
def create_rest_call(data, address, auth_token="none", method="POST"):
    switch = {
        "POST": requests.post,
        "GET": requests.get,
        "DELETE": requests.delete,
        "PATCH": requests.patch,
    }
    headers = {}
    headers["Content-Type"] = 'application/json'

    # Dump the data to Json so the curl call can take it in.
    data = json.dumps(data, indent=4)

    if auth_token == "none":
        headers["cache-control"] = "no-cache"
    else:
        headers["Authorization"] = auth_token

    print(f'==== {method} CALL ====')
    print(f'Sending data: {data}')
    print(f'To addr: {address}')

    try:
        r = switch[method](address, data=data, headers=headers, timeout=30)
        r.raise_for_status()
    except HTTPError as http_err:
        print_error(f'HTTP error occurred: {http_err}')
    except Exception as err:
        print_error(f'Other error occurred: {err}')
    else:
        jsonResponse = {}
        if r.text:
            jsonResponse = json.loads(r.text)
        print(f'Response: {jsonResponse}')
        print('=====')
        return jsonResponse
