from python_helpers.create_rest_call import create_rest_call
import time

def create_flow(controller_address, auth_token, flow):
    data = {}

    data["name"] = flow
    post_address = "{}/flow".format(controller_address)
    jsonResponse = create_rest_call(data, post_address, auth_token)
    flow_id = jsonResponse["id"]
    return flow_id

def create_flow_if_not_exist(controller_address, auth_token, flow):
    try:
      id = get_id(controller_address, flow, auth_token)
      return id
    except StopIteration:
      return create_flow(controller_address, auth_token, flow)

def restart_flow(controller_address, flow_id, flow_name, auth_token):
  flow = get_flow_by_id(controller_address, flow_id, auth_token)
  if flow.get("isActivated", False) == True:
    stop_flow(controller_address, flow_id, flow_name, auth_token)
    time.sleep(3)
  start_flow(controller_address, flow_id, flow_name, auth_token)

def start_flow(controller_address, flow_id, flow_name, auth_token):
    data = {}
    data["name"] = flow_name
    data["isActivated"] = True
    post_address = "{}/flow/{}".format(controller_address, flow_id)
    create_rest_call(data, post_address, auth_token, method="PATCH")

def stop_flow(controller_address, flow_id, flow_name, auth_token):
    data = {}
    data["name"] = flow_name
    data["isActivated"] = False
    post_address = "{}/flow/{}".format(controller_address, flow_id)
    create_rest_call(data, post_address, auth_token, method="PATCH")

def delete_flow(controller_address, flow_id, auth_token):
    data = {}
    post_address = "{}/flow/{}".format(controller_address, flow_id)
    create_rest_call(data, post_address, auth_token, method="DELETE")

def get_flow_by_name(controller_address, flow_name, auth_token):
    flows = get_all(controller_address, auth_token)
    return next(x for x in flows if x["name"] == flow_name)

def get_flow_by_id(controller_address, flow_id, auth_token):
    data = {}
    post_address = "{}/flow/{}".format(controller_address, flow_id)
    json_response = create_rest_call(data, post_address, auth_token, method="GET")
    return json_response

def get_id(controller_address, flow_name, auth_token):
    return get_flow_by_name(controller_address, flow_name, auth_token)["id"]

def get_all(controller_address, auth_token):
    data = {}
    flow_ids = {}
    post_address = "{}/flow".format(controller_address)
    json_response = create_rest_call(data, post_address, auth_token, method="GET")
    return json_response["flows"]
