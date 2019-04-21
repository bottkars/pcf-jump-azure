## Pivotal OPS Manager SAML integration with Azure Active Directory

this guide should asssi when integrating OPSMAN with Azure Active Directory

## Prerequisites

### Create OPS Manager Admin Client

If you do not have yet created an Automation Client for OPS Manager, do it *NOW*
The Admin Client must be used for automation Tasks with e.g. om cli, as programmatically login is NOT avialble when using SAML
There are several ways to create an OPS Manager Automation Client:

- Using the OPSMAN API
  when you first-time setup the Operations Manager ( from 2.5 ) by using the key *precreated_client_secret* :
  
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
uaac 
uaac client add post-created-client --authorized_grant_types client_credentials --authorities opsman.admin, scim.read,scim.write,zone.uaa,uaa.admin --secret example-secret
```

## Azure Config

### Create and AzureAD Application

From Azure Piortal, go to ActiveDirectory --> Enterprise Applications

<img width="200" alt="AAD_1" src="https://user-images.githubusercontent.com/8255007/56279931-62b2dd80-6109-11e9-8e00-4b502df9f99e.png">

click on 'new application' and select the Tile non-gallery application
![image](https://user-images.githubusercontent.com/8255007/56280181-f5537c80-6109-11e9-8a40-d833bb456edc.png)

Assign a meaningfull name for the Application ( Note: An (Identity Provider ) Application can only can map to *ONE* Assertion Consumer.

![image](https://user-images.githubusercontent.com/8255007/56280316-39df1800-610a-11e9-8395-d785be7ead61.png)

From the Manage Tab, select *Single Sign On*
![image](https://user-images.githubusercontent.com/8255007/56280316-39df1800-610a-11e9-8395-d785be7ead61.png)

From SSO, select the SAML Tile:
<img width="600" alt="saml" src="https://user-images.githubusercontent.com/8255007/56281159-35b3fa00-610c-11e9-80fd-8bb6e82195fa.png">

### Complete Step (1)the basic SAML configuration:

The Reply Address is *https://<your-ops-manager>:443/uaa* . I *Highly Recommend* using the same for the Identifier (Entity ID) , as this helps you to stay unique with the Identifier
  
![image](https://user-images.githubusercontent.com/8255007/56282418-68abbd00-610f-11e9-93eb-9023469de92d.png)
  
Click SAVE.

Now an important step:

### Step  (2) User Attributes & Claims

Click on the Edit Button
<img width="450" alt="group_claims" src="https://user-images.githubusercontent.com/8255007/56282795-45cdd880-6110-11e9-9d8c-9f9ff16a7927.png">

By default, no Group Claims are returned from , as shown above
Click on the edit button in 'Groups returned in claim'
This will allow you to customize nthe rerturned claim
make sure you
- select Security Groups
- Source Attribute: Group IDS
- Customize the name of the group claim: user.groups ( <-- Iportant Step here ! )

<img width="300" alt="USER_CLAIM" src="https://user-images.githubusercontent.com/8255007/56284471-ce4e7800-6114-11e9-827b-f4e8e0878b86.png">

## Opsman Config













