from python_helpers.create_rest_call import create_rest_call


def get_agent_per_microservice(controller_address, auth_token, microservices):
    data = {}
    agent_uuids = {}
    post_address = "{}/iofog-list".format(controller_address)
    json_response = create_rest_call(data, post_address, auth_token, method="GET")
    for microserviceKey in microservices:
        microservice = microservices[microserviceKey]
        agent_uuids[microserviceKey] = next(x for x in json_response["fogs"] if x["name"] == microservice["agent-name"])
    return agent_uuids


def get_agent_info(agent):
    config = {}
    config.update(agent)
    return config


def update_agent(controller_address, uuid, fog_info, auth_token):
    url = "{}/iofog/{}".format(controller_address, uuid)
    return create_rest_call(fog_info, url, auth_token, method="PATCH")
