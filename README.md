# Azure Automation Runbooks
- Azure Automation Runbook is a nice way to automate the Azure & On-Prem environments. Now a days each organization is having hybrid mode. We can automate that using Azure Runbooks.
- On-Prem servers can be added where Runbook should be executed by using Azure ARC enabled VM.
- [*MSFT KB - Start a runbook in Azure Automation*](https://learn.microsoft.com/en-us/azure/automation/start-runbooks)
- [*MSFT KB - Automation Hybrid Runbook Worker overview*](https://learn.microsoft.com/en-us/azure/automation/automation-hybrid-runbook-worker)
- Supported RunBooks - **PowerShell** & **Python**.

## Azure Automation Runbooks-Implementation
- Create an Azure Automation Account.
- Create a Service principle.
- Grant Contributor access on subscription/RG for that newly created SPI.
- Bind a certificate with that SPI.
- Import that certificate into automation account.
- Create a SPI *connection* under Automation account.
- Create a PowerShell RunBook.
- Test the below code.
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



