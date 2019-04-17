## Pivotal OPS Manager SAML integration with Azure Active Directory


## Prerequisites
### Create OPS Manager Admin Client
If you do not have yet created an Automation CLient for OPS Manager, do it *NOW*
The Admin Client must be used for automation Tasks with e.g. om cli, as programaticaly login is NOT avialble when using saml
Therer are several ways to create an AOPS Manager Automation Client:

- Using the OPSMAN API
  when you first-time setup the Operations Manager by using the key *precreated_client_secret* :
  
```bash
curl "https://example.com/api/v0/setup" \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{ "setup": {
    "decryption_passphrase": "example-passphrase",
    "decryption_passphrase_confirmation":"example-passphrase",
    "eula_accepted": "true",
    "identity_provider": "internal",
    "admin_user_name": "user-ed942e358eb61868dc87",
    "admin_password": "example-password",
    "admin_password_confirmation": "example-password",
    "precreated_client_secret": "example-secret"
  } }'
```
  this will create an initial client id 'precreated-client' with the configured secret to be used for all automation tasks
  
  
  - Using UAAC ( if OM already Configured )
  
  target you opsman uaa endpoint:
```
uaac target pcf.pcfazure.labbuildr.com
uaac client add post-created-client --authorized_grant_types client_credentials --authorities opsman.admin, scim.read,scim.write,zone.uaa,uaa.admin --secret example-secret
  ```
