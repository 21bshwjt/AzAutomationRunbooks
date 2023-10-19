# Sent Email for KeyVault Secrets expiry from Azure Hybrid Worker
[CmdletBinding()]
Param() 

Begin {
    $dateformat = Get-Date -format 'MM.dd.yyyy.HH.mm.ss'
    $LoggingDirectory = "<Folder path>"
    $Logpath = "$($LoggingDirectory)\SecretExpiry_$($dateformat).log"
    Start-Transcript -Path $Logpath -Force
    $verbosepreference = "continue"
    $style = @'
        <style>
table {
    font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
    border-collapse: collapse;
    width: 100%
}
td, th {
    border: 1px solid #ddd;
    padding: 8px;
}
tr:nth-child(even){background-color:oldlace}
tr:hover {background-color: #ddd}

th{
    padding-top: 7px;
    padding-bottom: 7px;
    text-align: left;
    background-color: #08CD11;
    color: white

}
        </style>
'@ 

    $style1 = @'
        <style>
table {
    font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
    border-collapse: collapse;
    width: 100%
}
td, th {
    border: 1px solid #ddd;
    padding: 8px;
}
tr:nth-child(even){background-color:oldlace}
tr:hover {background-color: #ddd}

th{
    padding-top: 7px;
    padding-bottom: 7px;
    text-align: left;
    background-color: #CD2F08;
    color: white

}
        </style>
'@ 



    $ThumbPrint = (Get-ChildItem "Cert:\LocalMachine\my" | Where-Object { $_.Subject -eq "<Subject>" }).Thumbprint
    $ApplicationID = "<APPID>"
    $TenantID = "<TenantID>"
}
process {
 
    Connect-AzAccount -CertificateThumbprint $thumbprint -ApplicationId $ApplicationID -Tenant $TenantID -ServicePrincipal | Out-Null

    $VaultName = "KV_Name"
    $DaysNearExpiration = 15
    # Set the subscription context
    Set-AzContext -SubscriptionId "SUBID" | Out-Null
    #Get-AzKeyVault -VaultName $VaultName

    $ExpiredSecrets = @()
    $NearExpirationSecrets = @()
 
    #gather all key vaults from subscription
    if ($VaultName) {
        $KeyVaults = Get-AzKeyVault -VaultName $VaultName
    }
    else {
        $KeyVaults = Get-AzKeyVault
    }
    #check date which will notify about expiration
    $ExpirationDate = (Get-Date (Get-Date).AddDays($DaysNearExpiration) -Format yyyyMMdd)
    $CurrentDate = (Get-Date -Format yyyyMMdd)
    $today = Get-Date
    # iterate across all key vaults in subscription
    foreach ($KeyVault in $KeyVaults) {
        # gather all secrets in each key vault
        $SecretsArray = Get-AzKeyVaultSecret -VaultName $KeyVault.VaultName
        foreach ($secret in $SecretsArray) {
            # check if expiration date is set
            if ($secret.Expires) {
                $secretExpiration = Get-date $secret.Expires -Format yyyyMMdd
                # check if expiration date set on secret is before notify expiration date
                if ($ExpirationDate -gt $secretExpiration) {
                    # check if secret did not expire yet but will expire soon
                    if ($CurrentDate -lt $secretExpiration) {
                        $NearExpirationSecrets += [pscustomobject]@{
                            Name             = $secret.Name;
                            Category         = 'SecretNearExpiration';
                            #KeyVaultName   = $KeyVault.VaultName;
                            ExpirationDate   = $secret.Expires;
                            DaysUntillExpiry = New-TimeSpan -Start $today.ToString('yyyy-MM-dd') -End $($secret.Expires).ToString('yyyy-MM-dd')
                        }
                    }
                    # secret is already expired
                    else {
                        $ExpiredSecrets += [pscustomobject]@{
                            Name           = $secret.Name;
                            Category       = 'SecretExpired';
                            #KeyVaultName   = $KeyVault.VaultName;
                            ExpirationDate = $secret.Expires;
                        }
                    }
 
                }
            }
        }
         
    }
 
    Write-Verbose "Total number of expired secrets: $($ExpiredSecrets.Count)"
    #Write-Verbose "$ExpiredSecrets" -Verbose
  
    Write-Verbose "Total number of secrets near expiration: $($NearExpirationSecrets.Count)"
    #Write-Output $NearExpirationSecrets

    if ($ExpiredSecrets -or $NearExpirationSecrets) {

        $Html = $NearExpirationSecrets | ConvertTo-Html -Fragment -PreContent "<h3><center>Weekly Report Created on $(Get-Date) | <font color = #161CE9> Total number of secrets near expiration: $($NearExpirationSecrets.Count)</font></Center></h3>"
        [string]$htmlMail = ConvertTo-HTML -Head $style -Body $Html

        $Html1 = $ExpiredSecrets | ConvertTo-Html -Fragment -PreContent "<h3><center>Weekly Report Created on $(Get-Date) | <font color = #161CE9> Total number of expired secrets: $($ExpiredSecrets.Count)</font></Center></h3>"
        [string]$htmlMail1 = ConvertTo-HTML -Head $style1 -Body $Html1

        $parameters = @{
            From       = '<EMAIL>'
            To = @("<EMAIL>")
            Subject    = "$VaultName | Secret Expiry Notification"
            Body       = "$htmlMail1 $htmlMail"
            BodyAsHTML = $true
            SmtpServer = '<SMTP>'
        }
        Send-MailMessage @parameters
    }
    else {
        Write-Output "There is no secret near to expiry"
    }
}
end {
    Stop-Transcript
}
