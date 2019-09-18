az group delete --name ${JUMPBOX_RG} --yes                                                                                                                       ✔  10822
az group delete --name ${ENV_NAME} --yes                   
ssh-keygen -R "${JUMPBOX_NAME}.${AZURE_REGION}.cloudapp.azure.com" 