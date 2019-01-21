# pcf-jump-azure

<img src="https://docs.pivotal.io/images/PVLG-PivotalApplicationService-Symbol.png" width="100"><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Heart_coraz%C3%B3n.svg/800px-Heart_coraz%C3%B3n.svg.png" width="100">
<img src="https://docs.pivotal.io/images/icon_microsoft_azure@2x.png" width="100">

## Overview

pcf-jump-azure creates an ubuntu based jumpbox to deploy Pivotal PAS (2.4 and above) on azure  
It will pave the infrastructure using Pivotal [terraforming-azure](https://github.com/pivotal-cf/terraforming-azure).  
PCF Operations Manager will be installed and configured using Pivotal [om cli](https://github.com/pivotal-cf/om).  
Optionally, PAS will be deployed using [om cli](https://github.com/pivotal-cf/om).  

## features

- automated opsman deployment and configuration
- pas infrastructure paving
- autopilot for starting pas, mysql, rabbit and spring deployment (will take several hours )
- certificate generation using selfsigned or let´s encrypt [certificates](#certificates)
- [sendgrid](/sendgrid.md) integration for notifications and user sign up
- dns configuration and check

## usage

create an .env file using the [.env.example](/.env.example)  
Parameter Explanation in this [table](#env-variables)  
if you need a full parameter set or a minimum depends on your customizations (e.g. [sendgrid](/sendgrid.md) and others )

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

you are now good to go to deploy  
[with minimum parameters](#deployment-with-minimum-param-set)  
[with full parameters](#deployment-with-full-param-set)
[with parameter file](#deployment-using-parameter-file)
also, note that AUTOPILOT is disabled by default now.  
you can set the Environment for PAS_AUTOPILOT or use -pasAutopilot=TRUE during deployment.  
if not using autopilot, see [Post Deployment Steps](#post-deploy) for more Details

## deployment with minimum param set

the minimum parameter set uses defaults where possible

### validate minimum

```bash
az group create --name ${JUMPBOX_RG} --location ${AZURE_REGION}
az group deployment validate --resource-group ${JUMPBOX_RG} \
    --template-uri https://raw.githubusercontent.com/bottkars/pcf-jump-azure/${BRANCH}/azuredeploy.json \
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

### deploy minimum

```bash
az group create --name ${JUMPBOX_RG} --location ${AZURE_REGION}
az group deployment create --resource-group ${JUMPBOX_RG} \
    --template-uri "https://raw.githubusercontent.com/bottkars/pcf-jump-azure/${BRANCH}/azuredeploy.json" \
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

## deployment with full param set

the full parameter set´s optiional Values like smtp config

### validate full

```bash
az group create --name ${JUMPBOX_RG} --location ${AZURE_REGION}
az group deployment validate --resource-group ${JUMPBOX_RG} \
    --template-uri "https://raw.githubusercontent.com/bottkars/pcf-jump-azure/${BRANCH}/azuredeploy.json" \
    --parameters \
    sshKeyData="$(cat ~/${JUMPBOX_NAME}.pub)" \
    adminUsername=${ADMIN_USERNAME} \
    dnsLabelPrefix=${JUMPBOX_NAME} \
    clientSecret=${AZURE_CLIENT_SECRET} \
    clientID=${AZURE_CLIENT_ID} \
    tenantID=${AZURE_TENANT_ID} \
    subscriptionID=${AZURE_SUBSCRIPTION_ID} \
    pivnetToken=${PCF_PIVNET_UAA_TOKEN} \
    envName=${ENV_NAME} \
    envShortName=${ENV_SHORT_NAME} \
    opsmanImage=${OPS_MANAGER_IMAGE} \
    opsmanImageRegion=${OPS_MANAGER_IMAGE_REGION} \
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
    smtpStarttls=${SMTP_STARTTLS} \
    useSelfCerts=${USE_SELF_CERTS} \
    _artifactsLocation=${ARTIFACTS_LOCATION} \
    vmSize=${VMSIZE} \
    pasEdition=${PAS_EDITION}
```

### deploy full

```bash
az group create --name ${JUMPBOX_RG} --location ${AZURE_REGION}
az group deployment create --resource-group ${JUMPBOX_RG} \
    --template-uri "https://raw.githubusercontent.com/bottkars/pcf-jump-azure/${BRANCH}/azuredeploy.json" \
    --parameters \
    sshKeyData="$(cat ~/${JUMPBOX_NAME}.pub)" \
    adminUsername=${ADMIN_USERNAME} \
    dnsLabelPrefix=${JUMPBOX_NAME} \
    clientSecret=${AZURE_CLIENT_SECRET} \
    clientID=${AZURE_CLIENT_ID} \
    tenantID=${AZURE_TENANT_ID} \
    subscriptionID=${AZURE_SUBSCRIPTION_ID} \
    pivnetToken=${PCF_PIVNET_UAA_TOKEN} \
    envName=${ENV_NAME} \
    envShortName=${ENV_SHORT_NAME} \
    opsmanImage=${OPS_MANAGER_IMAGE} \
    opsmanImageRegion=${OPS_MANAGER_IMAGE_REGION} \
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
    smtpStarttls=${SMTP_STARTTLS} \
    useSelfCerts=${USE_SELF_CERTS} \
    _artifactsLocation=${ARTIFACTS_LOCATION} \
    vmSize=${VMSIZE} \
    pasEdition=${PAS_EDITION}
```

## deployment using parameter file

you also might want to deploy the template using an parameter file.  
simply create a local azuredeploy.parameter.json file from the [example](./azuredeploy.parameters.example.json)

then run 

```bash
az group create --name <RG_NAME> --location <AZURE_REGION>
az group deployment create --resource-group <rg_name> \
    --template-uri https://raw.githubusercontent.com/bottkars/pcf-jump-azure/${BRANCH}/azuredeploy.json \
    --parameters @azuredeploy.parameters.json

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
 ssh -i ~/${JUMPBOX_NAME} ${ADMIN_USERNAME}@${JUMPBOX_NAME}.${AZURE_REGION}.cloudapp.azure.com
```

tail the installation log  

```bash
tail -f ~/install.log
```
## post deploy

if you do not autodeploy ( default behaviour ), you can kickstart the deployment of all components from the jumphost:

### pas

using selfsigned [certificates](#certificates)

```bash
./create_self_certs.sh
./deploy_pas.sh
```

or using Let´s encrypt

```bash
./create_certs.sh
./deploy_pas.sh
```

### mysql

requires pas deployed

 ```bash
./deploy_mysql.sh
```

### rabbit

requires pas deployed

 ```bash
./deploy_rabbit.sh
```

### spring service

requires pas, rabbit and mysql deployed

 ```bash
./deploy_spring.sh
```

## cleanup

```bash
az group delete --name ${JUMPBOX_RG} --yes
az group delete --name ${ENV_NAME} --yes
ssh-keygen -R "${JUMPBOX_NAME}.${AZURE_REGION}.cloudapp.azure.com"
```

## certificates

the deployment uses self-signed certificates by default. to uses automated generation of Let´s encrypt Certificates, set

```bash
USE_SELF_CERTS="FALSE"
```

and use the [Full Deployment Method](#deploy-full)

## env variables

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
**PAS_EDITION**             | pasEdition|cf|no|cf or srt deployment
**OPS_MANAGER_IMAGE_REGION**|opsmanImageRegion|westeurope|yes|the region where to download opsman from. Values are westeurope, westus, eastus, southeastasia
## required nameserver delegation

make sure that your domain has a ns resource record to your pcf domain.  
the  following nameserver entries must be part of the resource record:  

```bash
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
