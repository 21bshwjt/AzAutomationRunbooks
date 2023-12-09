# Get the Azure Automation connection object
$connection = Get-AutomationConnection -Name "<Azure_SPI>"

# Connect to Azure using the connection object
Try {
    Connect-MgGraph -ClientId $connection.ApplicationID `
        -TenantId $connection.TenantID `
        -CertificateThumbprint $connection.CertificateThumbprint
}    
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}
# Set the subscription context
Set-AzContext -SubscriptionId "<Sub_Id>" | Out-Null

Connect-MgGraph -ClientId $client_id -TenantId $tenant_id -CertificateThumbprint $thumb_print -NoWelcome

$result = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users"
#$result.value
$result.value | Select-Object id,displayName,userPrincipalName
