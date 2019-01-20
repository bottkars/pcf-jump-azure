#!/usr/bin/env bash
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