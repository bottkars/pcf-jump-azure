# pcf-jump-azure

## example

```bash
az group create --name test --location westeurope
```

```bash
az group deployment create --resource-group test \
    --template-uri https://raw.githubusercontent.com/bottkars/pcf-jump-azure/master/azuredeploy.json \
    --parameters @azuredeploy.parameters.json \
    sshKeyData="$(cat ~/opsman.pub)"
```



