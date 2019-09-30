import sys
import os
import yaml
import argparse

sys.path.append('..')

from python_helpers.create_rest_call import create_rest_call
import python_helpers.catalog_service as catalog_service
import python_helpers.microservice_service as microservice_service
import python_helpers.flow_service as flow_service
import python_helpers.agent_service as agent_service

from colorama import init
from python_helpers.pretty_print import print_info
from python_helpers.pretty_print import print_success
from python_helpers.pretty_print import print_error


#
# Load all the config from external config file
#
# Returns configPath, metaPath, weightPath as strings (if valid)
# Throws ValueError if there are any problems in loading config.
#
def load_config(config_file):
    # Check that everything we need exists
    if not os.path.exists(config_file):
        raise ValueError("Invalid config path `" +
                         os.path.abspath(config_file) + "`")

    # Read our config file
    with open(config_file, 'r') as ymlfile:
        theConfig = yaml.load(ymlfile, Loader=yaml.FullLoader)

    print_info("Loaded config from '" + os.path.abspath(config_file) + "`")
    print(theConfig)

    return theConfig


def iofog_auth(controller_address, email, password):
    data = {}
    data["email"] = email
    data["password"] = password
    post_address = "{}/user/login".format(controller_address)
    jsonResponse = create_rest_call(data, post_address)
    auth_token = jsonResponse["accessToken"]
    return auth_token


def clean(theConfig):
    # Get values from config
    user = theConfig["user"]
    controller = theConfig["controller"]
    controller_address = controller["address"] + "/api/v3"
    microservices = theConfig["microservices"]
    routes = theConfig["routes"]

    print_info("====> Beginning cleanup process")
    print_info("====> Authenticating")
    auth_token = iofog_auth(controller_address, user["email"], user["password"])

    try:
        print_info("====> Retrieving flow id")
        flow_id = flow_service.get_id(controller_address, theConfig["flow"], auth_token)

        print_info("====> Deleting flow")
        print_info("====> Deleting the flow will remove the microservices and routes")
        flow_id = flow_service.delete_flow(controller_address, flow_id, auth_token)
    except Exception as err:
        print_error(f'Could not delete the flow. Error: {err}')

    try:
        catalog_items = []
        print_info("====> Listing catalog")
        catalog_list = catalog_service.get_catalog(controller_address, auth_token)
        for microservice in microservices.values():
            microservice_name = microservice["microservice"]["name"] + "_catalog"
            catalog_id = next(x for x in catalog_list if x["name"] == microservice_name)["id"]
            catalog_items.append(catalog_id)

        print_info("====> Deleting from catalog")
        catalog_service.delete_items(controller_address, catalog_items, auth_token)

        print_success("====> You are done !")
    except Exception as err:
        print_error(f'Could not remove from catalog. Error: {err}')
        print_error(sys.exc_info()[0])


def configure_agents(controller_address, auth_token, microservices, fog_per_microservice):

    for microserviceKey in microservices:
        microservice = microservices[microserviceKey]
        new_fog_config = microservice.get("agent-config", {})
        fog = fog_per_microservice[microserviceKey]
        if not new_fog_config:
            return
        # fog.update(new_fog_config)
        print_info("====> Updating Agent config")
        agent_service.update_agent(controller_address, fog["uuid"], new_fog_config, auth_token)


def setup(theConfig):
    # Get values from config
    user = theConfig["user"]
    controller = theConfig["controller"]
    controller_address = controller["address"] + "/api/v3"
    microservices = theConfig["microservices"]
    routes = theConfig["routes"]

    print_info("====> Authenticating")
    auth_token = iofog_auth(controller_address, user["email"], user["password"])
    
    # Create our standard flow_id for everything else
    print_info("====> Creating or stoping existing flow")
    flow_id = flow_service.create_flow_if_not_exist(controller_address, auth_token, theConfig["flow"])
    # Stoping the flow
    flow_service.stop_flow(controller_address, flow_id, theConfig["flow"], auth_token)

    # Updating agent config
    print_info("====> Getting Agent uuids")
    fog_per_microservice = agent_service.get_agent_per_microservice(controller_address, auth_token, microservices)

    print_info("====> Configuring Agents")
    configure_agents(controller_address, auth_token, microservices, fog_per_microservice)
    
    # Updating catalog
    print_info("====> Registering microservices images to the catalog")
    catalog_id_per_microservice = catalog_service.setup(controller_address, auth_token, microservices)

    # Setup the microservices in controller and attached to our agent
    print_info("====> Creating microservices and routes")
    microservice_service.setup(controller_address, flow_id, fog_per_microservice, catalog_id_per_microservice,
                               auth_token, microservices, routes)

    # Start up the rest of the service
    print_info("====> Starting flow")
    flow_service.restart_flow(controller_address, flow_id, theConfig["flow"], auth_token)

    print_success("====> You are done !")


if __name__ == "__main__":

    # Initialize colorama
    init(autoreset=True)

    parser = argparse.ArgumentParser(description='Setup microservices according to a YAML configuration file')
    parser.add_argument('--clean', dest='clean', action='store_true', default=False,
                        help='Clean previously set up microservices from the controller')
    parser.add_argument('--config', dest='config_file', action='store',
                        default='config.yml', help='Specify the config file (default to config.yaml)')

    args = parser.parse_args()

    print_info("===> Loading our configuration")
    config = load_config(args.config_file)
    if args.clean:
        clean(config)
    else:
        setup(config)
