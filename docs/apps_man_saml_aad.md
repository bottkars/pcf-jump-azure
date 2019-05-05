# Integrate Pivotal Apps Manager with SAML AA SSO

## create enterprise app

## configure pcf

## assign users

## assign admins

### login uaac



```
GROUP_ID=fd570d0b-ae8b-45f8-871e-7e40ef426dd8
uaac group map --name scim.read ${GROUP_ID} --origin labbuildrAD
uaac group map --name scim.write ${GROUP_ID} --origin labbuildrAD
uaac group map --name cloud_controller.admin ${GROUP_ID} --origin labbuildrAD
```


