# pcf-jump-azure

## usage 
create an .env file using the .env.example  
the .env vile requires the following variables to be set:

**IAAS**=*the iaas environment, azure*  
**JUMPBOX_RG**=*the name of the ressource group for the JumpBox*  
**JUMPBOX_NAME**=*the JumpBox hostname*   
**ADMIN_USERNAME**=*ubuntu*  
**AZURE_CLIENT_ID**=*fake your azure client id*  
**AZURE_CLIENT_SECRET**=*fake your azure client secret*  
**AZURE_REGION**=*westeurope*  
**AZURE_SUBSCRIPTION_ID**=*fake your azure subscription id*  
**AZURE_TENANT_ID**=*fake your azure tenant*  
**PCF_PIVNET_UAA_TOKEN**=*fave your pivnet refresh token*  
**OM_HOSTNAME**=*opsman.yourdomain.com*  
**ENV_NAME**=*yourenv*  
**ENV_SHORT_NAME**=*yourenvshort*  
**OPS_MANAGER_IMAGE_URI**=*"https://opsmanagerwesteurope.blob.core.windows.net/images/ops-manager-2.3-build.194.vhd"*  
**DNS_SUFFIX**=*yourdomain.com*  
**DNS_SUBDOMAIN**=*yourpcf*  
**PRODUCT_SLUG**=*elastic-runtime*  
**RELEASE_ID**=*220833*  

```bash
source .env
```
## create a aah keypair for the admin user

```bash
ssh-keygen -t rsa -f opsman -C ${ADMIN_USERNAME}
```

## create the target resource group for the jumpbox

```bash
az group create --name ${JUMPBOX_RG} --location ${AZURE_REGION}
```

## start the deployment

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
az group delete --name ${JUMPBOX_RG} --yes
ssh-keygen -R "${JUMPBOX_NAME}.${AZURE_REGION}.cloudapp.azure.com"
```



