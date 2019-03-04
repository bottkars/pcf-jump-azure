#!/usr/bin/env bash
source ~/.env.sh
cd ${HOME_DIR}
MYSELF=$(basename $0)
IFS='_' read -r TASK PRODUCT_SLUG <<< "${MYSELF}"
PRODUCT_SLUG=$(echo "${PRODUCT_SLUG}" | cut -f 1 -d '.')
echo "We got ${PRODUCT_SLUG}"

mkdir -p ${LOG_DIR}
exec &> >(tee -a "${LOG_DIR}/${MYSELF}.$(date '+%Y-%m-%d-%H').log")
exec 2>&1
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -n|--NO_DOWNLOAD)
    NO_DOWNLOAD=TRUE
    echo "No download is ${NO_DOWNLOAD}"
    # shift # past value if  arg value
    ;;
    -d|--DO_NOT_APPLY_CHANGES)
    NO_APPLY=TRUE
    echo "No APPLY is ${NO_APPLY}"
    # shift # past value ia arg value
    ;;  
    -a|--APPLY_ALL)
    APPLY_ALL=TRUE
    echo "APPLY ALL is ${NO_APPLY}"
    # shift # past value ia arg value
    ;;        
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
shift
done
set -- "${POSITIONAL[@]}" # restore positional parameters

cat << EOF > ${TEMPLATE_DIR}/${PRODUCT_SLUG}_vars.yaml
product_name: scanner
pcf_pas_network: pcf-pas-subnet
pcf_service_network: pcf-services-subnet
EOF

echo "Caller evaluation"

if  [ ! -z "$NO_APPLY" ] ; then
    echo "calling tile Installer with No Product Apply"
    ${SCRIPT_DIR}/deploy_tile.sh -t ${PRODUCT_SLUG} -d
    
    elif [ ! -z ${APPLY_ALL} ] ; then
echo "calling tile Installer with apply All for ${PRODUCT_SLUG}"
    ${SCRIPT_DIR}/deploy_tile.sh -t ${PRODUCT_SLUG}
else
    echo "calling tile Installer with Product Apply"
    ${SCRIPT_DIR}/deploy_tile.sh -t ${PRODUCT_SLUG} -a
fi
echo "$(date) end deploy ${PRODUCT_SLUG}"