# Runon : Azure 
# Get the Azure Automation connection object
$connection = Get-AutomationConnection -Name "<SPIName>"

Try
{
Connect-AzAccount -ServicePrincipal `
    -Tenant $connection.TenantID `
    -ApplicationId $connection.ApplicationID `
    -CertificateThumbprint $connection.CertificateThumbprint
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

# Set the subscription context
Set-AzContext -SubscriptionId "<Subscription_ID>"

#Get VMs from a RG
Get-AzVM -ResourceGroupName "<RG_Name>" | Select-Object Name,Type
