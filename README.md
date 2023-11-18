# Azure Automation Runbooks & Hybrid Workers
- Azure Automation Runbook is a nice way to automate the Azure & On-Prem environments. Now a days each organization is having hybrid mode. We can automate that using Azure Runbooks.
- Azure and on-prem VMs (**Windows & Linux**) can be added as Hybrid Workers.
- [*MSFT KB - Start a runbook in Azure Automation*](https://learn.microsoft.com/en-us/azure/automation/start-runbooks)
- [*MSFT KB - Automation Hybrid Runbook Worker overview*](https://learn.microsoft.com/en-us/azure/automation/automation-hybrid-runbook-worker)
- Supported RunBooks - **PowerShell** & **Python**.
  
## Use case
- **Automate Routine tasks on Azure & On-Prem**.
- **Schedule Jobs from a centralized location & run on multiple environments**.
- **Leverage Azure SSO**.
- **Streamlined Maintenance**.
- **Source Control**

## Use case Example Flow & Enhancement
- Run a job (Runbook) on multiple On-Prem domains to get the Powered-off VMs (Hyper-V/V-Centers) reports in CSV format.
- Import those CSVs into an Azure Storage blob.
- Run another job (Runbook) & download all the CSVs & send those reports (CSVs) to the respective Team.
- Run single code from a single place on multiple domains.
- Send all CSVs using a single e-mail.

### **In this scenario, Azure Enterprise Application facilitates authentication to Azure, but Azure AD User-Managed Identity can also be utilized for achieving Azure Single Sign-On (SSO)**.
  
### Sample Code to upload the CSV into a Storage Blob
```powershell
#pwsh
# Get the Azure Automation connection object
$connection = Get-AutomationConnection -Name "<AZ_SPI_Connection_Name>"

# Connect to Azure using the connection object
Try {
    Connect-AzAccount -ServicePrincipal `
        -Tenant $connection.TenantID `
        -ApplicationId $connection.ApplicationID `
        -CertificateThumbprint $connection.CertificateThumbprint | Out-Null
}    
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}
# Set the subscription context
Set-AzContext -SubscriptionId "<SUBID>" | Out-Null
# Define Variables
$storageAccountRG = "<storageAccountRG>"
$storageAccountName = "<storageAccountName>"
$storageContainerName = "<storageContainerName>"
$localPath = "<Local_Path>"

# Select the right Azure Subscription
#Select-AzSubscription -SubscriptionId $SubscriptionId

# Get Storage Account Key
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccountRG -AccountName $storageAccountName).Value[0]

# Set AzStorageContext
$destinationContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Generate SAS URI
$containerSASURI = New-AzStorageContainerSASToken -Context $destinationContext -ExpiryTime(get-date).AddSeconds(3600) -FullUri -Name $storageContainerName -Permission rw

# Upload File using AzCopy
Write-Output "Uploading $Filename into $storageContainerName container"
azcopy copy $localPath $containerSASURI
```  

## Benefits of Azure Automation Account Hybrid workers
- Extended Automation Reach.
- Unified Management; Azure Automation facilitates the centralized management of resources, seamlessly integrating both cloud and on-premises environments.
- Efficient Resource Utilization.
- Enhanced Security and Compliance.
- Scalability and Flexibility.
- Streamlined Maintenance.
- **Schedule a single code for "n" number of On-Prem domains**.

## Azure Automation Runbooks-Implementation
- Create an Azure Automation Account (Need to activate Contributor Role).
- Create a Service principle.
- Grant Contributor access on subscription/RG for that newly created SPI.
- Bind a certificate with that SPI.
- Import that certificate into the automation account.
- Create a SPI *connection* under Automation account.
- Create a PowerShell RunBook.
- Test the below code from the Automation account.
 
```powershell
# Azure DevOps

# Get the Azure Automation connection object
$connection = Get-AutomationConnection -Name "<AzureConnection_Name>"

# Connect to Azure using the connection object
Try {
    Connect-AzAccount -ServicePrincipal `
        -Tenant $connection.TenantID `
        -ApplicationId $connection.ApplicationID `
        -CertificateThumbprint $connection.CertificateThumbprint | Out-Null
}    
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

Set-AzContext -SubscriptionId "<SubID>"
Get-AzVM -ResourceGroupName "<RG_Name>" | Select-object name
```
### Test the below code from Windows VM/Hybrid Worker.
```powershell
# Need to import the same certificate(.pfx) into the computer store.
$ThumbPrint = (Get-ChildItem "Cert:\LocalMachine\my" | Where-Object { $_.Subject -eq "CN=<Certificate Subject>" }).Thumbprint
$AppID = "***************************"
$TenantId = "*****************************"


Connect-AzAccount -CertificateThumbprint $ThumbPrint -ApplicationId $AppID -Tenant $TenantId -ServicePrincipal
Set-AzContext -SubscriptionId "***************************"
```
