# pcf-jump-azure

pcf-jump-azure creates an ubuntu based jumpbox to deploy pivotal pas on azure  

it will pave the infrastructure using terraform.
PCF Operations Manager will be installed and configured.  

Optionally, PAS will be deployed

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
**ENV_NAME**=*this name will be prefix for azure resources and you opsman hostname*  
**ENV_SHORT_NAME**=*will be used as prefix for storage accounts and other azure resources*  
**OPS_MANAGER_IMAGE_URI**=*default "https://opsmanagerwesteurope.blob.core.windows.net/images/ops-manager-2.4-build.131.vhd"*  
**PCF_DOMAIN_NAME**=*yourdomain.com*  
**PCF_SUBDOMAIN_NAME**=*yourpcf*  
**PRODUCT_SLUG**=*default: elastic-runtime*  
**RELEASE_ID**=*default: 259105*  
**PCF_NOTIFICATIONS_EMAIL**=*"user@example.com"*  
**PCF_OPSMAN_USERNAME**=*opsman*  
**PAS_AUTOPILOT**=*TRUE or FALSE* Autoinstall PAS  
**PCF_PAS_VERSION**=*default 2.4.0 or greater*  

```bash
source .env
```

## create a aah keypair for the admin user

```bash
ssh-keygen -t rsa -f ~/opsman -C ${ADMIN_USERNAME}
```

## start the deployment

```bash
az group create --name ${JUMPBOX_RG} --location ${AZURE_REGION}
az group deployment create --resource-group ${JUMPBOX_RG} \
    --template-uri https://raw.githubusercontent.com/bottkars/pcf-jump-azure/master/azuredeploy.json \
    --parameters \
    adminUsername=${ADMIN_USERNAME} \
    sshKeyData="$(cat ~/opsman.pub)" \
    dnsLabelPrefix=${JUMPBOX_NAME} \
    clientSecret=${AZURE_CLIENT_SECRET} \
    clientID=${AZURE_CLIENT_ID} \
    tenantID=${AZURE_TENANT_ID} \
    subscriptionID=${AZURE_SUBSCRIPTION_ID} \
    pivnetToken=${PCF_PIVNET_UAA_TOKEN} \
    env_name=${ENV_NAME} \
    env_short_name=${ENV_SHORT_NAME} \
    ops_manager_image_uri=${OPS_MANAGER_IMAGE_URI} \
    pcf_domain_name=${PCF_DOMAIN_NAME} \
    pcf_subdomain_name=${PCF_SUBDOMAIN_NAME} \
    opsmanUsername=${PCF_OPSMAN_USERNAME} \
    product_slug=${PRODUCT_SLUG} \
    release_id=${RELEASE_ID} \
    notificationsEmail=${PCF_NOTIFICATIONS_EMAIL} \
    pasAutopilot=${PAS_AUTOPILOT} \
    pasVersion=${PCF_PAS_VERSION}
```

```bash
 ssh -i ~/opsman ubuntu@${JUMPBOX_NAME}.${AZURE_REGION}.cloudapp.azure.com
```

## cleanup

```bash
az group delete --name ${JUMPBOX_RG} --yes
az group delete --name ${ENV_NAME} --yes
ssh-keygen -R "${JUMPBOX_NAME}.${AZURE_REGION}.cloudapp.azure.com"
```