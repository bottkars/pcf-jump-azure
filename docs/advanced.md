# Advanced tasks

## connect to bosh

to connect to bosh from the Jumpbox

```bash
source ~/.env.sh

export OM_TARGET=pcf.${PCF_SUBDOMAIN_NAME}.${PCF_DOMAIN_NAME}
export OM_USERNAME=${PCF_OPSMAN_USERNAME}
export OM_PASSWORD=${PIVNET_UAA_TOKEN}

sudo mkdir -p /var/tempest/workspaces/default

sudo sh -c \
  "om \
    --skip-ssl-validation \
    --target ${PCF_OPSMAN_FQDN} \
    --username ${PCF_OPSMAN_USERNAME} \
    --password ${PIVNET_UAA_TOKEN} \
    curl \
      --silent \
      --path "/api/v0/security/root_ca_certificate" |
        jq --raw-output '.root_ca_certificate_pem' \
          > /var/tempest/workspaces/default/root_ca_certificate"

export $( \
  om \
    --skip-ssl-validation \
    curl \
      --silent \
      --path /api/v0/deployed/director/credentials/bosh_commandline_credentials | \
        jq --raw-output '.credential' \
)


```

## ssh into the opsmanager

from the jumpbox, you can  

```bash
source .env.sh
ssh -i opsman ${ADMIN_USERNAME}@${PCF_OPSMAN_FQDN}
```


## om from jump

```
source ~/.env.sh
PIVNET_UAA_TOKEN=$PIVNET_UAA_TOKEN

export OM_TARGET=${PCF_OPSMAN_FQDN}
export OM_USERNAME=${PCF_OPSMAN_USERNAME}
export OM_PASSWORD="${PIVNET_UAA_TOKEN}"
```

```bash
ADD_USER=user@pivotal.io
uaac user add ${ADD_USER} -p ChangeMe --emails ${ADD_USER}
uaac member add cloud_controller.admin ${ADD_USER}
uaac member add uaa.admin ${ADD_USER}
uaac member add scim.read ${ADD_USER}
uaac member add scim.write ${ADD_USER}
```

```
uaac group map --name scim.read "admin" --origin labbuildrad
uaac group map --name scim.write "admin" --origin labbuildrad
uaac group map --name cloud_controller.admin "admin" --origin labbuildrad
```

