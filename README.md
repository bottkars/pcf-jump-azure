# pcf-jump-azure

## usage tbd

```bash
source .env
```

```bash
az group create --name test --location ${AZURE_REGION} 
```

```bash
az group deployment create --resource-group test \
    --template-uri https://raw.githubusercontent.com/bottkars/pcf-jump-azure/master/azuredeploy.json \
    --parameters @azuredeploy.parameters.json \
    sshKeyData="$(cat ~/opsman.pub)" \
    clientSecret=${AZURE_CLIENT_SECRET} \
    clientID=${AZURE_CLIENT_ID} \
    tenantID=${AZURE_TENANT_ID} \
    subscriptionID=${AZURE_SUBSCRIPTION_ID} \
    uaaToken=${PCF_PIVNET_UAA_TOKEN} \
    omHostname=${OM_HOSTNAME} \
    pivnetToken=${PCF_PIVNET_UAA_TOKEN} \
    env_name=${ENV_NAME} \
    env_short_name=${ENV_SHORT_NAME} \
    ops_manager_image_uri=${OPS_MANAGER_URI} \
    dns_suffix=${DNS_SUFFIX} \
    dns_subdomain=${DNS_SUBDOMAIN} \
    adminUsername=${ADMIN_USERNAME}
```

```bash
 ssh -i ~/opsman ubuntu@pasjumpbox.westeurope.cloudapp.azure.com
```

```bash
ssh-keygen -R "pasjumpbox.westeurope.cloudapp.azure.com"
```

