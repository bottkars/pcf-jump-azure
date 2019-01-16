# integrating sendgrid with pas

## signup with sendgrid

if you do not have a sendgrid account, signup fro a free one [here](https://signup.sendgrid.com/)

## create api key

in sendgrid web ui, go to account --> api keys  
click on create API Key

![create api key](https://user-images.githubusercontent.com/8255007/51247514-a6247100-198d-11e9-82cf-06824d16bfa7.png)

select restricted and enable mail send.

once api key is created, copy the key to your env file  
the key is only show once !!!

![imapi key](https://user-images.githubusercontent.com/8255007/51247772-6b6f0880-198e-11e9-948f-0e805e4e05e4.png)



## populate the following env vars before deployment

```bash
SMTP_ADDRESS="smtp.sendgrid.net"
SMTP_IDENTITY="apikey"
SMTP_PASSWORD="your api key"
SMTP_FROM="your from address"
SMTP_PORT="587"
SMTP_STARTTLS="true"
```