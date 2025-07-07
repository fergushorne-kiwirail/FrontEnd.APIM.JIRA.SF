environment = "UT"

keyvault_integration_services = [
    {
      keyvault_name           = "ut-aue-integration-kv"
      keyvault_resource_group = "ut-aue-integrationshared-rg"
    },
    {
      keyvault_name           = "ut-aus-integration-kv"
      keyvault_resource_group = "ut-aus-integrationshared-rg"
    }
]