# Azure Automation Runbooks & Hybrid Workers
- Azure Automation Runbook is a nice way to automate the Azure & On-Prem environments. Now a days each organization is having hybrid mode. We can automate that using Azure Runbooks.
- On-Prem servers can be added where Runbook should be executed by using Azure ARC enabled VM.
- [*MSFT KB - Start a runbook in Azure Automation*](https://learn.microsoft.com/en-us/azure/automation/start-runbooks)
- [*MSFT KB - Automation Hybrid Runbook Worker overview*](https://learn.microsoft.com/en-us/azure/automation/automation-hybrid-runbook-worker)
- Supported RunBooks - **PowerShell** & **Python**.
  
## Benefits of Azure Automation Account Hybrid workers
- Extended Automation Reach.
- Unified Management; Azure Automation facilitates the centralized management of resources, seamlessly integrating both cloud and on-premises environments.
- Efficient Resource Utilization.
- Enhanced Security and Compliance.
- Scalability and Flexibility.
- Streamlined Maintenance.
- [*MSFT KB - Hybrid Workers*](https://learn.microsoft.com/en-us/azure/automation/automation-hybrid-runbook-worker).
- **Schedule a single code for "n" number of On-Prem domains**.

## Azure Automation Runbooks-Implementation
- Create an Azure Automation Account.
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



