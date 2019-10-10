# Healthcare Demo - Heart Rate from Bluetooth Wearable

This repository contains microservices and packaging code for starting up a healthcare demonstration on Eclipse ioFog. 
The demonstration detects the presence of a [Schosche RHYTHM+ wearable](https://www.scosche.com/catalog/product/view/id/9140) 
via Bluetooth Low Energy and then gathers the heart rate data and assigns the configured name to the data and passes it 
on to a JSON Viewer as an ioMessage. 

This demo showcases the power of the [ioFog RESTBlue](https://github.com/eclipse-iofog/restblue) microservice 
which abstracts the Bluetooth Low Energy capabilities of the edge node and makes them available via a REST API for easy 
connection and programming.  

## Requirements

Before running the script you must:
 * Have an ioFog deployment with at least one agent, one controller and one connector
    * IoFog Controller version >= 1.1.0 (`iofog-controller controller version`)
    * IoFog Connector version >= 1.1.0 (`iofog-connector version`)
    * IoFog Agent version >= 1.1.0  (`iofog-agent version`)
 * Have a user registered on the controller
 

### Configuration of the Scosche RHYTHM+ sensor adapter microservice

Set the config in Controller for this microservice if you want to either activate the "simulation mode" or if you want 
to label the heart rate data. If you set "test_mode" to true then the microservice will not look for a Bluetooth device 
but will send randomized heart rate data instead with the label you specify. 

```
{
    "data_label":"Your Name",
    "test_mode":false
}
```

The default values are "true" and "Anonymous Person" for the config so you will get that if you don't set the config.

### Viewing the sensor readings

Once the Demo is running, the JSON output can be viewed by connecting to the JSON-REST-API micro service. You will be 
able to access the viewer on `<AGENT_IP>:5000`. **Note**: this port will ONLY work
if you have updated to the EAP packages. Otherwise, it is not exported by the older version of ioFog Agent.