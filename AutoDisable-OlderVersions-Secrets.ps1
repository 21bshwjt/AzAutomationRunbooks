<#
Azure KeyVault - AutoDisable older Versions of Secrets from a KeyVault.
######################################################################
### Change into the Code ###
You need to change line numbers 7 (Your_SPI), 21 (Subscription_ID) & 24 (KeyVault).
###----------------------###
#>

# Get the Azure Automation connection object
$connection = Get-AutomationConnection -Name "<Your_SPI>"

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
Set-AzContext -SubscriptionId "<Subscription_ID>" | Out-Null

# Set the KeyVault
$KeyVaultName = "<KeyVault>"
$secrets = Get-AzKeyVaultSecret -VaultName $KeyVaultName

# Disable all the older versions of Secrets & keep the latest one only.
foreach ($secret in $secrets) {
    $ListedVersions = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name ($secret.Name) -IncludeVersions | Select-Object * | 
        Sort-Object -Descending Created | Select-Object -Skip 1
    $ListedVersions
    $ListedVersions | ForEach-Object -Process {Update-AzKeyVaultSecret -VaultName $KeyVaultName -Name $($PSItem.Name) -Version $($PSItem.Version) -Enable $false -Verbose}
}
