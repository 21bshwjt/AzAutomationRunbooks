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
Set-AzContext -SubscriptionId "c7791184-ab41-458a-b044-f371730f1d84" | Out-Null

$query = "AzureDiagnostics | where ResultType == 'Failed' | project TimeGenerated, RunbookName_s, RunOn_s ,ResultType | where TimeGenerated > now() - 4h | sort by TimeGenerated asc"
$WorkspaceID = "76f2115e-891c-44d4-90e0-b89a60db6602"
$kqlQuery = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID -Query $query

If ($kqlQuery.Results) {
    $kqlQuery.Results
    # Send Email (If needed)
}
else {
    Write-Output "There is no failure job sincs last 4 hours."
}
