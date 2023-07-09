<#
Azure KeyVault - AutoDisable older Versions of Secrets from a KeyVault. 
#>

# Get the Azure Automation connection object
$connection = Get-AutomationConnection -Name "AzureSPI"

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
Set-AzContext -SubscriptionId "Your_Sub_ID" | Out-Null


$KeyVaultName = "Your_KV"
$secrets = Get-AzKeyVaultSecret -VaultName $KeyVaultName

foreach ($secret in $secrets) {
    $ListedVersions = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name ($secret.Name) -IncludeVersions | Select-Object * | 
        Sort-Object -Descending Created | Select-Object -Skip 1
    $ListedVersions
    $ListedVersions | ForEach-Object -Process {Update-AzKeyVaultSecret -VaultName $KeyVaultName -Name $($PSItem.Name) -Version $($PSItem.Version) -Enable $false -Verbose}
}
