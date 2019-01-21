#!/usr/bin/env bash

MYSELF=$(basename $0)
mkdir -p ${HOME_DIR}/logs
exec &> >(tee -a "${HOME_DIR}/logs/${MYSELF}.$(date '+%Y-%m-%d-%H').log")
exec 2>&1
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -n|--NO_DOWNLOAD)
    NO_DOWNLOAD="$2"
    echo $NO_DOWNLOAD
    # shift # past value
    ;;
    -d|--DO_NOT_APPLY_CHANGES)
    NO_APPLY="$2"
    echo $NO_APPLY
    ## shift # past value
    ;;    
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
shift
done