# pcf-jump-azure

pcf-jump-azure creates an ubuntu based jumpbox to deploy Pivotal PAS (2.4 and above) on azure  

It will pave the infrastructure using Pivotal [terraforming-azure](https://github.com/pivotal-cf/terraforming-azure).  

PCF Operations Manager will be installed and configured using Pivotal [om cli](https://github.com/pivotal-cf/om).  
Optionally, PAS will be deployed using [om cli](https://github.com/pivotal-cf/om).  
|## usage 
create an .env file using the .env.example  
the .env file requires at the following variables to be set:  

| variable|parameter|default value|mandatory|description|
|---|---|---|---|---|
|**JUMPBOX_RG**|||yes|the name of the ressource group for the JumpBox  
**JUMPBOX_NAME**|dnsLabelPrefix|-|yes|the JumpBox hostname , must be unique for the region ! 
**ADMIN_USERNAME**|adminUsername|ubuntu|no|the jimpbox os username 
**AZURE_CLIENT_ID**|clientID||true|*Azure Service Principal*  
**AZURE_CLIENT_SECRET**|clientSecret|||*Service Principal client secret*  
**AZURE_REGION**||||used from az resource group command, no default 
**AZURE_SUBSCRIPTION_ID**||||Your Azure Subscription ID,  
**AZURE_TENANT_ID**||||Your AZURE tenant 
**PCF_PIVNET_UAA_TOKEN**|||yes|Your Token from Pivotal Network 
**PCF_DOMAIN_NAME**|||yes|the domain your pcf subdomain will be hosted in 
**PCF_SUBDOMAIN_NAME**|||yes|the subdomain name that will be created in your resource group
**ENV_SHORT_NAME**|env_short_name||yes|*yourshortname* will be used as prefix for storage accounts and other azure resources. make sure you check storage account availability, see further down below  
**ENV_NAME**|env_name|pcf||*pcf* this name will be prefix for azure resources and you opsman hostname  
**OPS_MANAGER_IMAGE_URI**|ops_manager_image_uri|https://opsmanagerwesteurope.blob.core.windows.net/images/ops-manager-2.4-build.131.vhd|no| a 2.4 opsman image url
**RELEASE_ID**|release_id|259105|no|**  
**PCF_NOTIFICATIONS_EMAIL**|user@example.com"||*"*  
**PCF_OPSMAN_USERNAME**||||*opsman*  
**NET_16_BIT_MASK**||||*10.10* 16 bit network mask, defaul 10.10  
**PAS_AUTOPILOT**||||*FALSE* Autoinstall PAS when set to true  
**PCF_PAS_VERSION**||||*2.4.1* the version of PAS, must be 2.4.0 or greater  
**SMTP_ADDRESS**||||*"mysmtp.example.com"  
**SMTP_IDENTITY**||||*"mysmtpuser"  
**SMTP_PASSWORD**||||*"mysmtppass"  
**SMTP_FROM**||||*"from@example"  
**SMTP_PORT**||||*"587"  
**SMTP_STARTTLS**||||*"true"  

source the env file  
```bash
source .env
```

## create a ssh keypair for the admin user ( if not already done )

```bash
ssh-keygen -t rsa -f ~/${JUMPBOX_NAME} -C ${ADMIN_USERNAME}
```

## check availability of storage account  

```bash
az storage account check-name --name ${ENV_SHORT_NAME}director
```

## start the deployment with minimum param set

```bash
az group create --name ${JUMPBOX_RG} --location ${AZURE_REGION}
az group deployment create --resource-group ${JUMPBOX_RG} \
    --template-uri https://raw.githubusercontent.com/bottkars/pcf-jump-azure/master/azuredeploy.json \
    --parameters \
    adminUsername=${ADMIN_USERNAME} \
    sshKeyData="$(cat ~/${JUMPBOX_NAME}.pub)" \
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
    pcf_subdomain_name=${PCF_SUBDOMAIN_NAME}
```

## start the deployment with full param set

```bash
az group create --name ${JUMPBOX_RG} --location ${AZURE_REGION}
az group deployment create --resource-group ${JUMPBOX_RG} \
    --template-uri https://raw.githubusercontent.com/bottkars/pcf-jump-azure/master/azuredeploy.json \
    --parameters \
    sshKeyData="$(cat ~/${JUMPBOX_NAME}.pub)" \
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
    release_id=${RELEASE_ID} \
    notificationsEmail=${PCF_NOTIFICATIONS_EMAIL} \
    net_16_bit_mask=${NET_16_BIT_MASK} \
    pasAutopilot=${PAS_AUTOPILOT} \
    pasVersion=${PCF_PAS_VERSION} \
    smtpAddress=${SMTP_ADDRESS} \
    smtpIdentity=${SMTP_IDENTITY} \
    smtpPassword=${SMTP_PASSWORD} \
    smtpFrom=${SMTP_FROM} \
    smtpPort=${SMTP_PORT} \
    smtpStarttls=${SMTP_STARTTLS}
```

## debugging/ monitoring

it is recommended to check the deployment logs. the azure rm command might timeout as the pas deployment takes time. that will not have an impact on the deployment.  
watching the JUMPHost resource group creation  

```bash
watch az resource list --output table --resource-group ${JUMPBOX_RG}
```

watching the pcf resource group creation  

```bash
watch az resource list --output table --resource-group ${ENV_NAME}
```

ssh into the Jumpbox  

```bash
 ssh -i ~/${JUMPBOX_NAME} ubuntu@${JUMPBOX_NAME}.${AZURE_REGION}.cloudapp.azure.com
```

tail the installation log  

```bash
tail -f ~/install.log
```

## cleanup

```bash
az group delete --name ${JUMPBOX_RG} --yes
az group delete --name ${ENV_NAME} --yes
ssh-keygen -R "${JUMPBOX_NAME}.${AZURE_REGION}.cloudapp.azure.com"
```

## required nameserver delegation

make sure that your domain has a ns resource record to your pcf domain.  
the  following nsmaserver entries must be part of the resource record:   

```
ns1-07.azure-dns.com.
ns2-07.azure-dns.net.
ns3-07.azure-dns.org.
ns4-07.azure-dns.info.
ns1-03.azure-dns.com.
ns2-03.azure-dns.net.
ns3-03.azure-dns.org.
ns4-03.azure-dns.info.
ns1-09.azure-dns.com.
ns2-09.azure-dns.net.
ns3-09.azure-dns.org.
ns4-09.azure-dns.info.
ns4-01.azure-dns.info.
ns4-02.azure-dns.info.
ns4-04.azure-dns.info.
ns4-05.azure-dns.info.
ns4-06.azure-dns.info.
ns4-08.azure-dns.info.
ns4-10.azure-dns.info.
ns1-01.azure-dns.com.
ns1-02.azure-dns.com.
ns1-04.azure-dns.com.
ns1-05.azure-dns.com.
ns1-06.azure-dns.com.
ns1-08.azure-dns.com.
ns1-10.azure-dns.com.
ns2-01.azure-dns.net.
ns2-02.azure-dns.net.
ns2-04.azure-dns.net.
ns2-06.azure-dns.net.
ns2-05.azure-dns.net.
ns2-08.azure-dns.net.
ns2-10.azure-dns.net.
ns3-01.azure-dns.org.
ns3-02.azure-dns.org.
ns3-04.azure-dns.org.
ns3-05.azure-dns.org.
ns3-06.azure-dns.org.
ns3-08.azure-dns.org.
ns3-10.azure-dns.org.
```
