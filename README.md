# pcf-jump-azure

## usage tbd
create an .env file using the .env.example  
the .env vile requires the following variables to be set:

**IAAS**=azure
JUMPBOX_RG=RG_JUMPBOX
JUMPBOX_NAME=your_jumpbox_hostname
ADMIN_USERNAME=ubuntu
AZURE_CLIENT_ID=fake your azure client id
AZURE_CLIENT_SECRET=fake your azure client secret
AZURE_REGION=westeurope
AZURE_SUBSCRIPTION_ID=fake your azure subscription id
AZURE_TENANT_ID=fake your azure tenant
PCF_PIVNET_UAA_TOKEN=fave your pivnet refresh token
OM_HOSTNAME=opsman.yourdomain.com
ENV_NAME=yourenv
ENV_SHORT_NAME=yourenvshort
OPS_MANAGER_IMAGE_URI="https://opsmanagerwesteurope.blob.core.windows.net/images/ops-manager-2.3-build.194.vhd"
DNS_SUFFIX=yourdomain.com
DNS_SUBDOMAIN=yourpcf
PRODUCT_SLUG=elastic-runtime
RELEASE_ID=220833


```bash
source .env
az group create --name ${JUMPBOX_RG} --location ${AZURE_REGION}
```

```bash
az group deployment create --resource-group ${JUMPBOX_RG} \
    --template-uri https://raw.githubusercontent.com/bottkars/pcf-jump-azure/master/azuredeploy.json \
    --parameters @azuredeploy.parameters.json \
    sshKeyData="$(cat ~/opsman.pub)" \
    dnsLabelPrefix=${JUMPBOX_NAME} \
    clientSecret=${AZURE_CLIENT_SECRET} \
    clientID=${AZURE_CLIENT_ID} \
    tenantID=${AZURE_TENANT_ID} \
    subscriptionID=${AZURE_SUBSCRIPTION_ID} \
    omHostname=${OM_HOSTNAME} \
    pivnetToken=${PCF_PIVNET_UAA_TOKEN} \
    env_name=${ENV_NAME} \
    env_short_name=${ENV_SHORT_NAME} \
    ops_manager_image_uri=${OPS_MANAGER_IMAGE_URI} \
    dns_suffix=${DNS_SUFFIX} \
    dns_subdomain=${DNS_SUBDOMAIN} \
    adminUsername=${ADMIN_USERNAME} \
    product_slug=${PRODUCT_SLUG} \
    release_id=${RELEASE_ID}
```

```bash
 ssh -i ~/opsman ubuntu@${JUMPBOX_NAME}.${AZURE_REGION}.cloudapp.azure.com
```

## cleanup

```bash
az group delete --name ${JUMPBOX_RG}
ssh-keygen -R "${JUMPBOX_NAME}.${AZURE_REGION}.cloudapp.azure.com"
```



