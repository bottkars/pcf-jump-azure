# Credential for accessing the ERCS PrivilegedEndpoint, typically domain\cloudadmin
 $Creds = Get-Credential

 # Creating a PSSession to the ERCS PrivilegedEndpoint
 $Session = New-PSSession -ComputerName AzS-ERCS01 -ConfigurationName PrivilegedEndpoint -Credential $Creds

 # If you have a managed certificate use the Get-Item command to retrieve your certificate from your certificate location.
 # If you don't want to use a managed certificate, you can produce a self signed cert for testing purposes: 
 # 
 $Cert = New-SelfSignedCertificate -CertStoreLocation "cert:\CurrentUser\My" -Subject "CN=PCF_BoSH" -KeySpec KeyExchange
 #$Cert = Get-Item "<YourCertificateLocation>"

 $ServicePrincipal = Invoke-Command -Session $Session -ScriptBlock {New-GraphApplication -Name 'PCF_BoSH' -ClientCertificates $using:cert}
 $AzureStackInfo = Invoke-Command -Session $Session -ScriptBlock {Get-AzureStackStampInformation}
 $Session | Remove-PSSession

 # For Azure Stack development kit, this value is set to https://management.local.azurestack.external. This is read from the AzureStackStampInformation output of the ERCS VM.
 $ArmEndpoint = $AzureStackInfo.TenantExternalEndpoints.TenantResourceManager

 # For Azure Stack development kit, this value is set to https://graph.local.azurestack.external/. This is read from the AzureStackStampInformation output of the ERCS VM.
 $GraphAudience = "https://graph." + $AzureStackInfo.ExternalDomainFQDN + "/"

 # TenantID for the stamp. This is read from the AzureStackStampInformation output of the ERCS VM.
 $TenantID = $AzureStackInfo.AADTenantID

 # Register an AzureRM environment that targets your Azure Stack instance
 Add-AzureRMEnvironment `
 -Name "AzureStackUser" `
 -ArmEndpoint $ArmEndpoint

 # Set the GraphEndpointResourceId value
 Set-AzureRmEnvironment `
 -Name "AzureStackUser" `
 -GraphAudience $GraphAudience `
 -EnableAdfsAuthentication:$true

 Add-AzureRmAccount -EnvironmentName "AzureStackUser" `
 -ServicePrincipal `
 -CertificateThumbprint $ServicePrincipal.Thumbprint `
 -ApplicationId $ServicePrincipal.ClientId `
 -TenantId $TenantID

 # Output the SPN details
 $ServicePrincipal




 #### 

 # clientid

