# Get the Azure Automation connection object
$connection = Get-AutomationConnection -Name "<Azure_SPI>"

# Connect to Azure using the connection object
Try {
    Connect-MgGraph -ClientId $connection.ApplicationID `
        -TenantId $connection.TenantID `
        -CertificateThumbprint $connection.CertificateThumbprint `
        -NoWelcome
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

$result = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users"
#$result.value
$result.value | Select-Object id,displayName,userPrincipalName
