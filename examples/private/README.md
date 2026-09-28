This example illustrates a network isolated setup, combining vnet integration, ip restrictions and a private endpoint.

## Notes

Public access is disabled, inbound traffic reaches the logic app through the private endpoint only, additional modules are used to configure the virtual network, private dns zone and private endpoint.

Ip restrictions apply to the app itself, scm ip restrictions apply to the deployment endpoint, the header filters are only meaningful in combination with the front door service tag.
