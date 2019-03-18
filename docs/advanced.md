# Advanced tasks

## connect to bosh

to connect to bosh from the Jumpbox

```bash
source .env.sh
export OM_TARGET=pcf.${PCF_SUBDOMAIN_NAME}.${PCF_DOMAIN_NAME}
export OM_USERNAME=${PCF_OPSMAN_USERNAME}
export OM_PASSWORD=${PIVNET_UAA_TOKEN}
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
PIVNET_UAA_TOKEN=$PCF_PIVNET_UAA_TOKEN

export OM_TARGET=${PCF_OPSMAN_FQDN}
export OM_USERNAME=${PCF_OPSMAN_USERNAME}
export OM_PASSWORD="${PIVNET_UAA_TOKEN}"
```

