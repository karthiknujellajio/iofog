import json

from python_helpers.create_rest_call import create_rest_call
from python_helpers.pretty_print import print_error, print_info
import python_helpers.flow_service as flow_service

def create_microservice_curl_data(microservice, flow_id, fog_uuid, catalog_id):
    data = {}
    data["name"] = microservice["name"]

    if len(microservice.get("volumes", [])) > 0:
        data["volumeMappings"] = microservice["volumes"]

    if len(microservice.get("env", [])) > 0:
        data["env"] = microservice["env"]
    
    if len(microservice.get("ports", [])) > 0:
        data["ports"] = microservice["ports"]

    if "config" in microservice:
        data["config"] = json.dumps(microservice.get("config", {}))

    data["rootHostAccess"] = microservice.get("root-host", False)
    data["flowId"] = flow_id
    data["iofogUuid"] = fog_uuid
    data["catalogItemId"] = catalog_id

    return data

def update_microservice_curl_data(microservice, fog_uuid, catalog_id):
    data = {}
    data["name"] = microservice["name"]

    if len(microservice.get("volumes", [])) > 0:
        data["volumeMappings"] = microservice["volumes"]

    if len(microservice.get("env", [])) > 0:
        data["env"] = microservice["env"]
    
    # if len(microservice.get("ports", [])) > 0:
    #     data["ports"] = microservice["ports"]

    if "config" in microservice:
        data["config"] = json.dumps(microservice.get("config", {}))

    data["rootHostAccess"] = microservice.get("root-host", False)
    data["iofogUuid"] = fog_uuid
    # data["catalogItemId"] = catalog_id

    return data

def create_route(controller_address, auth_token, route):
    post_address = "{}/microservices/{}/routes/{}".format(controller_address, route["from"], route["to"])
    json_response = create_rest_call({}, post_address, auth_token)

def delete_route(controller_address, auth_token, route):
    post_address = "{}/microservices/{}/routes/{}".format(controller_address, route["from"], route["to"])
    json_response = create_rest_call({}, post_address, auth_token, method="DELETE")

def update_routing(controller_address, microservices_per_name, auth_token, routes):
    print_info("====> Update routing")
    updated = False
    for route in routes:
        # Check if route exists
        msvc = microservices_per_name.get(route["from"], None)
        dest_msvc = microservices_per_name.get(route["to"], None)
        if msvc == None:
            print_error("No source microservice for route: {} - Microservices: {}".format(route, microservices_per_name))
            continue
        if dest_msvc == None:
            print_error("No destination microservice for route: {} - Microservices: {}".format(route, microservices_per_name))
            continue
        route_exists = msvc != None and next((x for x in msvc.get("routes", []) if x == dest_msvc["uuid"]), False)
        # Create missing route
        if route_exists == False:
            print_info("====> Create new route")
            updated = True
            create_route(controller_address, auth_token,
                {
                    "from": microservices_per_name[route["from"]]["uuid"],
                    "to": microservices_per_name[route["to"]]["uuid"]
                })
    # Delete unecessary routes
    for microservice_name in microservices_per_name:
        microservice = microservices_per_name[microservice_name]
        microservice_routes = microservice.get("routes", [])
        for route in microservice_routes:
            route_needed = next((x for x in routes if x["from"] == microservice["name"] and microservices_per_name.get(x["to"], {"uuid": None})["uuid"] == route), False)
            if route_needed == False:
                print_info("====> Delete outdated route")
                updated = True
                delete_route(controller_address, auth_token,
                {
                    "from": microservice["uuid"],
                    "to": route
                })
    if updated == False:
        print_info("====> Routing is up-to-date.")
    else:
        print_info("====> Routing updated.")

def create_microservice(controller_address, microservice, fog_uuid, catalog_id, flow_id, auth_token):
    data = create_microservice_curl_data(microservice, flow_id, fog_uuid, catalog_id)
    post_address = "{}/microservices".format(controller_address)
    json_response = create_rest_call(data, post_address, auth_token)
    return json_response

def get_microservice_port_mapping(controller_address, microservice_uuid, auth_token):
    data = {}
    post_address = "{}/microservices/{}/port-mapping".format(controller_address, microservice_uuid)
    json_response = create_rest_call(data, post_address, auth_token, method="GET")
    return json_response["ports"]

def delete_microservice_port_mapping(controller_address, microservice_uuid, mapping, auth_token):
    data = {}
    post_address = "{}/microservices/{}/port-mapping/{}".format(controller_address, microservice_uuid, mapping["internal"])
    json_response = create_rest_call(data, post_address, auth_token, method="DELETE")
    return json_response

def create_microservice_port_mapping(controller_address, microservice_uuid, mapping, auth_token):
    data = mapping
    post_address = "{}/microservices/{}/port-mapping".format(controller_address, microservice_uuid)
    json_response = create_rest_call(data, post_address, auth_token)
    return json_response

def update_ports(controller_address, microservice, auth_token):
    print_info("====> Getting current port mapping")
    updated = False
    ports = microservice.get("ports", [])
    existing_port_mappings = get_microservice_port_mapping(controller_address, microservice["uuid"], auth_token)
    # Remove false port mapping
    for existing_mapping in existing_port_mappings:
        valid = next((x for x in ports if x["internal"] == existing_mapping["internal"] and x["external"] == existing_mapping["external"]), False)
        if valid == False:
            print_info("====> Remove outdated port mapping")
            updated = True
            delete_microservice_port_mapping(controller_address, microservice["uuid"], existing_mapping, auth_token)
    # Create missing port mapping
    for new_mapping in ports:
        exists = next((x for x in existing_port_mappings if x["internal"] == new_mapping["internal"] and x["external"] == new_mapping["external"]), False)
        if exists == False:
            print_info("====> Create new port mapping")
            updated = True
            create_microservice_port_mapping(controller_address, microservice["uuid"], new_mapping, auth_token)
    if updated == False:
        print_info("====> Port mapping is up-to-date")
    else:
        print_info("====> Port mapping updated")


def update_microservice(controller_address, microservice, fog_uuid, catalog_id, auth_token):
    data = update_microservice_curl_data(microservice, fog_uuid, catalog_id)
    post_address = "{}/microservices/{}".format(controller_address, microservice["uuid"])
    json_response = create_rest_call(data, post_address, auth_token, method="PATCH")
    # Update port mapping
    update_ports(controller_address, microservice, auth_token)
    return json_response

def get_microservices_by_flow_id(controller_address, flow_id, auth_token):
    data = {}
    post_address = "{}/microservices?flowId={}".format(controller_address, flow_id)
    json_response = create_rest_call(data, post_address, auth_token, method="GET")
    return json_response["microservices"]

def get_all_microservices(controller_address, auth_token):
    # Get all flows
    flows = flow_service.get_all(controller_address, auth_token)
    all_msvcs = []
    for flow in flows:
        all_msvcs.extend(get_microservices_by_flow_id(controller_address, flow["id"], auth_token))
    return all_msvcs

def get_microservice_by_name(controller_address, microservice_name, flow_id, auth_token):
    msvcs = get_microservices_by_flow_id(controller_address, flow_id, auth_token)
    return next(x for x in msvcs if x["name"] == microservice_name)

def setup(controller_address, flow_id, fog_per_microservice, catalog_ids, auth_token, microservices, routes):
    route = ""
    microservices_per_name = {}
    # Get exisiting microservices
    for microserviceKey in microservices:
        microservice = microservices[microserviceKey]
        name = microservice["microservice"]["name"]
        try:
            msvc = get_microservice_by_name(controller_address, name, flow_id, auth_token)
            microservices_per_name[name] = msvc
        except StopIteration:
            microservices_per_name[name] = None
            continue
    # Create missing microservices
    for microserviceKey in microservices:
        microservice = microservices[microserviceKey]["microservice"]
        name = microservice["name"]
        fog_uuid = fog_per_microservice[microserviceKey]["uuid"]
        catalog_id = catalog_ids[microserviceKey]
        msvc = None
        if microservices_per_name[name] == None:
            msvc = create_microservice(controller_address, microservice, fog_uuid, catalog_id, flow_id, auth_token)
        else:
            microservice["uuid"] = microservices_per_name[name]["uuid"]
            update_microservice(controller_address, microservice, fog_uuid, catalog_id, auth_token)
            msvc = {**microservice, **microservices_per_name[name]}
        microservices_per_name[microservice["name"]] = msvc
    # Update routing
    update_routing(controller_address, microservices_per_name, auth_token, routes)

def delete_microservice(controller_address, microservice, auth_token):
    post_address = "{}/microservices/{}".format(controller_address, microservice["uuid"])
    json_response = create_rest_call({}, post_address, auth_token, method="DELETE")
    return json_response

def delete_all_by_catalog_id(controller_address, auth_token, catalog_id):
    msvcs = get_all_microservices(controller_address, auth_token)
    print("All microservices: {}".format(msvcs))
    for msvc in msvcs:
        if msvc["catalogItemId"] == catalog_id:
            delete_microservice(controller_address, msvc, auth_token)