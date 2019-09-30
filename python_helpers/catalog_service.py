from python_helpers.create_rest_call import create_rest_call
from python_helpers.pretty_print import print_info
import python_helpers.microservice_service as microservice_service

def create_catalog_curl_data(catalog_item):
    data = {}
    data["name"] = catalog_item["name"]
    data["images"] = []
    data["images"].append({'containerImage': '{}'.format(catalog_item["images"]["arm"]), 'fogTypeId': 2})
    data["images"].append({'containerImage': '{}'.format(catalog_item["images"]["x86"]), 'fogTypeId': 1})
    data["registryId"] = 1

    return data

def update_catalog(controller_address, auth_token, catalog_item):
    # Delete all microservices that uses this specific catalog item
    print_info("====> Deleting all microservices currently using this catalog item")
    microservice_service.delete_all_by_catalog_id(controller_address, auth_token, catalog_item["id"])
    # Update catalog item
    data = create_catalog_curl_data(catalog_item)
    if data == {}:
        # If data has failed to be created, exit here, and echo which service failed
        return "{} failed to create curl data".format(catalog_item)
    post_address = "{}/catalog/microservices/{}".format(controller_address, catalog_item["id"])
    json_response = create_rest_call(data, post_address, auth_token, method="PATCH")

def add_to_catalog(controller_address, auth_token, catalog_item):
    data = create_catalog_curl_data(catalog_item)
    if data == {}:
        # If data has failed to be created, exit here, and echo which service failed
        return "{} failed to create curl data".format(catalog_item)
    post_address = "{}/catalog/microservices".format(controller_address)
    return create_rest_call(data, post_address, auth_token)


def delete_by_id(controller_address, catalog_id, auth_token):
    post_address = "{}/catalog/microservices/{}".format(controller_address, catalog_id)
    create_rest_call({}, post_address, auth_token, method="DELETE")


def delete_items(controller_address, catalog_items, auth_token):
    for catalog_id in catalog_items:
        delete_by_id(controller_address, catalog_id, auth_token)

def get_catalog(controller_address, auth_token):
    post_address = "{}/catalog/microservices".format(controller_address)
    return create_rest_call({}, post_address, auth_token, method="GET")["catalogItems"]

def get_catalog_item_by_name(controller_address, name, auth_token):
    catalog_items = get_catalog(controller_address, auth_token)
    return next((x for x in catalog_items if x["name"] == name), None)

def is_same(yaml_item, existing_item):
    if len(yaml_item["images"]) != len(existing_item["images"]):
        return False
    for image_type in yaml_item["images"]:
        image = yaml_item["images"][image_type]
        same = next((x for x in existing_item["images"] if (image_type == "x86" and x["fogTypeId"] == 1 and x["containerImage"] == image) or (image_type == "arm" and x["fogTypeId"] == 2 and x["containerImage"] == image)), False)
        if same == False:
            return False
    return True

def setup(controller_address, auth_token, microservices):
    # For each microservice check if catalog item exists
    print_info("====> Reading the catalog")
    updated = False
    existing_catalog_items = get_catalog(controller_address, auth_token)
    catalog_ids = {}
    for microserviceKey in microservices:
        microservice = microservices[microserviceKey]
        catalog_item = {
            "images": microservice["images"],
            "name": microservice["microservice"]["name"] + "_catalog"
        }
        catalog_id = ""
        existing_catalog_item = next((x for x in existing_catalog_items if x["name"] == catalog_item["name"]), None)
        # If it does not exists yet, create
        if  existing_catalog_item == None:
            print_info("====> Adding to the catalog")
            updated = True
            catalog_id = add_to_catalog(controller_address, auth_token, catalog_item)["id"]
        # Otherwise, patch to update images
        else:
            catalog_item["id"] = existing_catalog_item["id"]
            # Check if images have changed
            if is_same(catalog_item, existing_catalog_item) == False:
                print_info("====> Updating a catalog item (Delete / Recreate)")
                updated = True
                # update_catalog(controller_address, auth_token, catalog_item)
                delete_by_id(controller_address, existing_catalog_item["id"], auth_token)
                catalog_id = add_to_catalog(controller_address, auth_token, catalog_item)["id"]
            else:
                catalog_id = catalog_item["id"]
        catalog_ids[microserviceKey] = catalog_id
    if updated == False:
        print_info("====> Catalog is up-to-date")
    else:
        print_info("====> Catalog updated")
    return catalog_ids
