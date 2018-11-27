# pcf-jump-azure

## usage tbd

```bash
AZURE_CLIENT_SECRET0<yourclientsecret> \
AZURE_CLIENT_ID=<yourclientid>
```

```bash
az group create --name test --location westeurope
```

```bash
az group deployment create --resource-group test \
    --template-uri https://raw.githubusercontent.com/bottkars/pcf-jump-azure/master/azuredeploy.json \
    --parameters @azuredeploy.parameters.json \
    sshKeyData="$(cat ~/opsman.pub)" \
    clientSecret=${AZURE_CLIENT_SECRET} \
    clientID=${AZURE_CLIENT_ID} \
    tenantID=${AZURE_TENANT} \
    subscriptionID=${AZURE_SUBSCRIPTION_ID}
```

```bash
ssh-keygen -R pasjumpbox
```

