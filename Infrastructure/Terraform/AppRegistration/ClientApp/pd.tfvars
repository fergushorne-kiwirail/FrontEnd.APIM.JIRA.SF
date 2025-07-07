environment = "PD"

keyvault_integration_services = [
    {
      keyvault_name           = "pd-aue-integration-kv"
      keyvault_resource_group = "pd-aue-integrationshared-rg"
    },
    {
      keyvault_name           = "pd-aus-integration-kv"
      keyvault_resource_group = "pd-aus-integrationshared-rg"
    }
]