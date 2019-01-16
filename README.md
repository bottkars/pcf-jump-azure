# pcf-jump-azure
## Overview
pcf-jump-azure creates an ubuntu based jumpbox to deploy Pivotal PAS (2.4 and above) on azure  
It will pave the infrastructure using Pivotal [terraforming-azure](https://github.com/pivotal-cf/terraforming-azure).  
PCF Operations Manager will be installed and configured using Pivotal [om cli](https://github.com/pivotal-cf/om).  
Optionally, PAS will be deployed using [om cli](https://github.com/pivotal-cf/om).  

## features
- automated opsman deployment and configuration
- pas infrastructure paving
- autopilot for starting pas, mysql, rabbit and spring deployment
- certificate generation using selfsigned or let´s encrypt certificates
- [sendgrid](/sendgrid.md) integration for notifications and user sign up
- dns configuration and check

## usage 
create an .env file using the [.env.example](/.env.example)  
the .env file requires at the following variables to be set:  

variable                    | azure rm parameter | default value     | mandatory         | description
----------------------------|--------------------|-------------------|-------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------
**JUMPBOX_RG**              |                    |                   | yes               | the name of the ressource group for the JumpBox
**JUMPBOX_NAME**            | dnsLabelPrefix     | -                 | yes               | the JumpBox hostname , must be unique for the region !
**ADMIN_USERNAME**          | adminUsername      | ubuntu            | no                | the jumpbox os username
**AZURE_CLIENT_ID**         | clientID           |                   | yes               | *Azure Service Principal*
**AZURE_CLIENT_SECRET**     | clientSecret       |                   | yes               | *Service Principal client secret*
**AZURE_REGION**            |                    |                   | yes               | used from az resource group command, no default
**AZURE_SUBSCRIPTION_ID**   | subscriptionID     |                   | yes               | Your Azure Subscription ID,
**AZURE_TENANT_ID**         | tenantID           |                   | yes               | Your AZURE tenant
**PCF_PIVNET_UAA_TOKEN**    | pivnetToken        |                   | yes               | Your Token from Pivotal Network
**PCF_DOMAIN_NAME**         | pcfDomainName      |                   | yes               | the domain your pcf subdomain will be hosted in
**PCF_SUBDOMAIN_NAME**      | pcfSubdomainName   |                   | yes               | the subdomain name that will be created in your resource group
**ENV_SHORT_NAME**          | envShortName       |                   | yes               | *yourshortname* will be used as prefix for storage accounts and other azure resources. make sure you check storage account availability, see further down below
**ENV_NAME**                | envName            | pcf               | no, using default | *pcf* this name will be prefix for azure resources and you opsman hostname
**OPS_MANAGER_IMAGE_URI**   | opsmanImageUri     | [opsurl](https://opsmanagerwesteurope.blob.core.windows.net/images/ops-manager-2.4-build.131.vhd)                  | no                | a 2.4 opsman image url
**PCF_NOTIFICATIONS_EMAIL** | notificationsEmail | user@example.com" | no                | wher to sent PCF Notifications
**PCF_OPSMAN_USERNAME**     | opsmanUsername     | opsman            | no                | *opsman*
**NET_16_BIT_MASK**         | net16bitmask       | 10.10             | no                | *16 bit networkdefault 10.10
**PAS_AUTOPILOT**           | pasAutopilot       | FALSE             |                   | Autoinstall PAS, RABBIT, MYSQL, Spring Service when set to true
**PCF_PAS_VERSION**         | pasVersion         | 2.4.1             | no                | the version of PAS, must be 2.4.0 or greater
**SMTP_ADDRESS**            | smtpAddress        | null              | no                | "mysmtp.example.com"
**SMTP_IDENTITY**           | smtpIdentity       | null              | no                | "mysmtpuser"
**SMTP_PASSWORD**           | smtpPassword       | null              | no                | "mysmtppass"
**SMTP_FROM**               | smtpFrom           | null              | no                | "from@example.com"
**SMTP_PORT**               | smtpPort           | null              | no                | "587"
**SMTP_STARTTLS**           | smtpStarttls       | false             | no                | true or false
**USE_SELF_CERTS**          | useSelfcerts       | true              | no                | true or false

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
    envName=${ENV_NAME} \
    envShortName=${ENV_SHORT_NAME} \
    opsmanImageUri=${OPS_MANAGER_IMAGE_URI} \
    pcfDomainName=${PCF_DOMAIN_NAME} \
    pcfSubdomainName=${PCF_SUBDOMAIN_NAME}
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
    envName=${ENV_NAME} \
    envShortName=${ENV_SHORT_NAME} \
    opsmanImageUri=${OPS_MANAGER_IMAGE_URI} \
    pcfDomainName=${PCF_DOMAIN_NAME} \
    pcfSubdomainName=${PCF_SUBDOMAIN_NAME} \
    opsmanUsername=${PCF_OPSMAN_USERNAME} \
    notificationsEmail=${PCF_NOTIFICATIONS_EMAIL} \
    net16bitmask=${NET_16_BIT_MASK} \
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
