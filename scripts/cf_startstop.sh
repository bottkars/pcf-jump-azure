#!/usr/bin/env bash
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -start|--START_DEPLOYMENTS)
    cf_start=TRUE
    echo $cf_start
    # shift # past value
    ;;
    -stop|--STOP_DEPLOYMENTS)
    cf_stop=TRUE
    echo $cf_stop
    ## shift # past value
    ;; 
    -silent|--DONT_ASK)
    silent="-n"
    echo $silent
    ## shift # past value
    ;;        
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
shift
done

source .env.sh
export OM_TARGET=${PCF_OPSMAN_FQDN}
export OM_USERNAME=${PCF_OPSMAN_USERNAME}
export OM_PASSWORD="${PCF_PIVNET_UAA_TOKEN}"
export $( \
  om \
    --skip-ssl-validation \
    curl \
      --silent \
      --path /api/v0/deployed/director/credentials/bosh_commandline_credentials | \
        jq --raw-output '.credential' \
)


DEPLOYMENTS=$(bosh deployments --json | jq -r ".Tables[].Rows[].name")

REVERSE_DEPLOYMEMTS=$(echo $DEPLOYMENTS|tr ' ' '\n'|tac|tr '\n' ' ')

if [ "$cf_stop" = "TRUE" ]; then
  for DEPLOYMENT in $REVERSE_DEPLOYMEMTS; do
      echo "$DEPLOYMENT found. Now Stopping"
      bosh -d $DEPLOYMENT vms
      bosh -d $DEPLOYMENT stop --hard $silent
      bosh -d $DEPLOYMENT vms
  done
fi

if [ "$cf_start" = "TRUE" ]; then
for DEPLOYMENT in $DEPLOYMENTS; do
    echo "$DEPLOYMENT found. Now Starting"
    bosh -d $DEPLOYMENT vms
    bosh -d $DEPLOYMENT start $silent
    bosh -d $DEPLOYMENT vms
done
fi

