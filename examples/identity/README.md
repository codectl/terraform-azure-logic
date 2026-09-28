This example illustrates a user assigned identity setup, where the storage connection is retrieved from key vault instead of passed as an access key.

## Notes

The storage account name and access key are mutually exclusive with the key vault secret id, only one of both approaches can be used.

The user assigned identity needs secret read permissions before the logic app is created, key vault references in app settings resolve through the same identity.
