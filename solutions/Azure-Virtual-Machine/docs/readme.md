# Azure Virtual Machine

This solution packages an Azure Resource Manager template and a PowerShell deployment helper for virtual machines connected to an existing subnet.

## Requirements

- Azure PowerShell (`Az.Accounts` and `Az.Resources`)
- An existing resource group and virtual network subnet
- An Azure Compute Gallery image ID or a marketplace image reference

## Deployment

Create a parameter file containing the non-secret settings. For example:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "virtualMachine": {
      "value": {
        "name": "example-vm",
        "instanceCount": 1,
        "vmSize": "Standard_D2s_v5",
        "adminUsername": "azureuser",
        "windowsOS": true,
        "imageReference": {
          "id": "/subscriptions/<subscription-id>/resourceGroups/<image-resource-group>/providers/Microsoft.Compute/galleries/<gallery>/images/<image>/versions/<version>"
        },
        "osDisk": {
          "storageAccountType": "Premium_LRS",
          "diskSizeGB": 128,
          "caching": "ReadWrite"
        },
        "vnetResourceGroup": "networking-rg",
        "vnetName": "shared-vnet",
        "subnetName": "workload",
        "domainJoin": false
      }
    },
    "tags": {
      "value": {
        "managedBy": "AzureArtifact"
      }
    }
  }
}
```

For a marketplace image, provide an `imageReference` object with `publisher`, `offer`, `sku`, and `version` instead of `id`.

After connecting to Azure and selecting the subscription, deploy to an existing resource group:

```powershell
.\deploy-vm.ps1 -ResourceGroupName 'workload-rg' -TemplateParameterFile '.\vm.parameters.json'
```

The helper prompts securely for the local administrator password. If `domainJoin` is enabled, it also prompts for the domain account password. Domain joining is supported for Windows VMs; the `virtualMachine` object must then include `domainName` and `domainUsername`.

The template creates one network interface and VM per `instanceCount`, attaches each interface to the specified existing subnet, and installs the Azure Monitor agent extension for the selected operating system. Review the parameter file and deployment plan before running; the deployment creates billable Azure resources.
