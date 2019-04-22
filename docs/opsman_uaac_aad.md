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

From Azure Portal, go to ActiveDirectory --> Enterprise Applications  

<img width="200" alt="Enterprise Applications" src="https://user-images.githubusercontent.com/8255007/56279931-62b2dd80-6109-11e9-8e00-4b502df9f99e.png">

click on 'new application' and select the Tile non-gallery application  
<img width="600" alt="New Application" src="https://user-images.githubusercontent.com/8255007/56280181-f5537c80-6109-11e9-8a40-d833bb456edc.png">

Assign a meaningful name for the Application ( Note: An (Identity Provider ) Application can only can map to *ONE* Assertion Consumer.

<img width="200" alt="New Application Name" src="https://user-images.githubusercontent.com/8255007/56280316-39df1800-610a-11e9-8395-d785be7ead61.png">

From the Manage Tab, select *Single Sign On*  
<img width="200" alt="SSO" src="https://user-images.githubusercontent.com/8255007/56466225-ebce5b00-640e-11e9-8b00-1461af657255.png">

From SSO, select the SAML Tile:  
<img width="600" alt="saml" src="https://user-images.githubusercontent.com/8255007/56281159-35b3fa00-610c-11e9-80fd-8bb6e82195fa.png">

### Complete Step (1)the basic SAML configuration:

The Reply Address is *https://<*your-ops-manager*>:443/uaa* . I *Highly Recommend* using the same for the Identifier (Entity ID) , as this helps you to stay unique with the Identifier  
  
<img width="300" alt="saml" src="https://user-images.githubusercontent.com/8255007/56282418-68abbd00-610f-11e9-93eb-9023469de92d.png">
  
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

### Assign Users

From Manage, select *Users and Groups*

<img width="300" alt="USER_CLAIM" src="https://user-images.githubusercontent.com/8255007/56466476-fdb1fd00-6412-11e9-8e27-0daec200be8e.png">

Click *Add Users*

<img width="500" alt="Add User" src="https://user-images.githubusercontent.com/8255007/56466612-0c4ce400-6414-11e9-8373-8efe6d114d7d.png">

Assign Users

<img width="500" alt="assign User" src="https://user-images.githubusercontent.com/8255007/56467722-09a5bb00-6423-11e9-93a3-b8c4b836efc3.png">

search for the group with OpsmanAdmin Users and click add Click Select  

<img width="400" alt="Select User" src="https://user-images.githubusercontent.com/8255007/56467763-63a68080-6423-11e9-9150-b17beaab7156.png">

finish by clicking on the Assign Bitoon assign

<img width="300" alt="Group Link" src="https://user-images.githubusercontent.com/8255007/56467774-89338a00-6423-11e9-8a6e-cbaf63021736.png">

Click on the  Group Name Link to get Details of the Group

<img width="400" alt="Highlighted Group" src="https://user-images.githubusercontent.com/8255007/56467783-b08a5700-6423-11e9-955e-1a331a35c876.png">

note id

<img width="400" alt="Group ID" src="https://user-images.githubusercontent.com/8255007/56467794-ce57bc00-6423-11e9-8494-48cbd7758b04.png">

## Opsman Config

From the Operation Manager Homepage, dropdown opsman settings on the right top menu

<img width="400" alt="USER_CLAIM" src="https://user-images.githubusercontent.com/8255007/56467811-0a8b1c80-6424-11e9-9ef2-f4f618b0cabb.png">

Click on SAML Integration to the left

<img width="400" alt="USER_CLAIM" src="https://user-images.githubusercontent.com/8255007/56467829-3e664200-6424-11e9-855a-a77f90f31ec4.png">



Now fill inm the Values: 

- Current Decryption Passphrase *your current opsman decryption passphrase*

- SAML IDP Metadata: The *App Federation Metadata Url* gathered from the SSO Tab IN Azure Active Directory

<img width="200" alt="Federation Metadata" src="https://user-images.githubusercontent.com/8255007/56485836-e6881380-64d5-11e9-9fde-1afd29e203c0.png">

- SAML Admin Group: The Group ID from Azure AD Application Assignements Group

<img width="200" alt="Group ID" src="https://user-images.githubusercontent.com/8255007/56467794-ce57bc00-6423-11e9-8494-48cbd7758b04.png">

- Groups Attribute: The Group claim we creted earlier in AzureAD, *user.groups* 

- check *Provision an Admin Client in the BOSH UAA*

apply changes will log you put of opsman
ponly aad from nopw

<img width="200" alt="Group ID" src="https://user-images.githubusercontent.com/8255007/56486844-65cb1680-64d9-11e9-8846-f7ad4a36f4cd.png">

tempest restart


![image](https://user-images.githubusercontent.com/8255007/56486878-87c49900-64d9-11e9-9771-e5d08d612220.png)



re-login with aad 

![image](https://user-images.githubusercontent.com/8255007/56486941-bfcbdc00-64d9-11e9-8eba-18105059fb16.png)



## Troubleshooting

[How to create a uaa client used for concourse pipelines in Operations Manager when SAML Authentication is enabled](https://community.pivotal.io/s/article/How-to-create-a-uaa-client-used-for-concourse-pipelines-in-Operations-Manager-when-SAML-Authentication-is-enabled)


[Required UAA Scopes for Pipeline Automation](https://github.com/pivotal-cf/pcf-pipelines/blob/ae434bea5b4e3fa2b70051aa70c885dc2fa12218/upgrade-ops-manager/README.md#saml-for-authn-on-ops-manager)










