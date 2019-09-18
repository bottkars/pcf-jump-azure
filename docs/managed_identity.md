# migrating to Managed Identities

add the MI nested template under Resources:

{
            "apiVersion": "2017-05-10",
            "name": "nestedTemplate",
            "type": "Microsoft.Resources/deployments",
            "resourceGroup": "[parameters('keyVaultRG')]",
            "dependsOn": [
                "[concat('Microsoft.Compute/virtualMachines/', variables('vmName'))]"
            ],
            "properties": {
                "mode": "Incremental",
                "template": {
                    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                    "contentVersion": "1.0.0.0",
                    "parameters": {},
                    "variables": {},
                    "resources": [
                        {
                            "type": "Microsoft.KeyVault/vaults/accessPolicies",
                            "name": "[concat(parameters('keyVaultName'), '/add')]",
                            "apiVersion": "2018-02-14",
                            "location": "[parameters('location')]",
                            "properties": {
                                "accessPolicies": [
                                    {
                                        "tenantId": "[subscription().tenantId]",
                                        "objectId": "[reference(concat(resourceId('Microsoft.Compute/virtualMachines', variables('vmName')), '/providers/Microsoft.ManagedIdentity/Identities/default'), '2015-08-31-PREVIEW').principalId]",
                                        "permissions": {
                                            "secrets": [
                                                "get",
                                                "list"
                                            ]
                                        }
                                    }
                                ]
                            }
                        }
                    ]
                },
                "parameters": {}
            }
        }

add to arm template under vm properties:

```json
            "identity": {
                "type": "SystemAssigned"
            },
```
