# Azure DevOps
<#
# Runon : Azure 
# Hybrid Worker : N/A
#>

# Get the Azure Automation connection object
$connection = Get-AutomationConnection -Name "<az_aaa_connection>"

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

# Set Subscription
Set-AzContext -SubscriptionId "SubID"

# Create RG Array
$RGArray = @("RG1", "RG2", "RG3")

# Poweroff the VMs
$RGArray | ForEach-Object -Process {Get-AzVm -ResourceGroupName $PSItem | Stop-AzVM -Force -Verbose}
