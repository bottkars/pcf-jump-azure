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
    omHostname=${OM_HOSTNAME} \
    pivnetToken=${PCF_PIVNET_UAA_TOKEN} \
    env_name=${ENV_NAME} \
    env_short_name=${ENV_SHORT_NAME} \
    ops_manager_image_uri=${OPS_MANAGER_URI} \
    dns_suffix=${DNS_SUFFIX} \
    dns_subdomain=${DNS_SUBDOMAIN} \
    adminUsername=${ADMIN_USERNAME} \
    product_slug=${PRODUCT_SLUG} \
    release_id=${RELEASE_ID}
```

```bash
 ssh -i ~/opsman ubuntu@pasjumpbox.westeurope.cloudapp.azure.com
```

```bash
ssh-keygen -R "pasjumpbox.westeurope.cloudapp.azure.com"
```

{"AZURE_CLIENT_ID":"6f029fa6-1c71-4d03-a989-9cc17bedc1ef","AZURE_CLIENT_SECRET":"FRRay++8SiGoig5j1afwrja7c8vZ7MoVo6njfakxFr4=","ADMIN_USERNAME":"ubuntu","AZURE_SUBSCRIPTION_ID":"90d4abb3-8c7b-48bb-bd16-63fd14bac8cb","AZURE_TENANT_ID":"e09df5d5-ce00-4433-8137-5d98a504ac82","PCF_PIVNET_UAA_TOKEN":"d8d5fc88ba684a1ab15a86a74dd5726e-r","OM_HOSTNAME":"opsman.pcfazure.labbuildr.com","ENV_NAME":"pcftest","ENV_SHORT_NAME":"kbpcf","OPS_MANAGER_IMAGE_URI":"","LOCATION":"eastus","DNS_SUFFIX":"labbuildr.com","DNS_SUBDOMAIN":"pcfazure","PRODUCT_SLUG":"elastic-runtime","RELEASE_ID":"220833"}