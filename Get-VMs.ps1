# Runon : Azure 
# Get the Azure Automation connection object
$connection = Get-AutomationConnection -Name "<SPIName>"

# Connect to Azure using the connection object
Connect-AzAccount -ServicePrincipal `
    -Tenant $connection.TenantID `
    -ApplicationId $connection.ApplicationID `
    -CertificateThumbprint $connection.CertificateThumbprint

# Set the subscription context
Set-AzContext -SubscriptionId "<Subscription_ID>"

#Get VMs from a RG
Get-AzVM -ResourceGroupName "<RG_Name>" | Select-Object Name,Type
