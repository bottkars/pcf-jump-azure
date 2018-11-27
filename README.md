# pcf-jump-azure

## example

```bash
az group create --name test --location westeurope
```

```bash
az group deployment create --resource-group test\
    --template-file azuredeploy.json \
    --parameters @azuredeploy.parameters.json sshKeyData="$(cat ~/opsman.pub)"
```



