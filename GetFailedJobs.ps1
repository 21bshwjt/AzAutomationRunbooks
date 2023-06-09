<#
# Runon : Azure 
#>

# Get the Azure Automation connection object
$connection = Get-AutomationConnection -Name "<SPI>"

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
Set-AzContext -SubscriptionId "<Sub_Id>" | Out-Null

$query = "AzureDiagnostics | where ResultType == 'Failed' | project TimeGenerated, RunbookName_s, RunOn_s ,ResultType | where TimeGenerated > now() - 4h | sort by TimeGenerated asc"
$WorkspaceID = "WorkspaceID"
$kqlQuery = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID -Query $query

If ($kqlQuery.Results) {
    $kqlQuery.Results
    # Send Email (If needed)
}
else {
    Write-Output "There is no failure job since last 4 hours."
}
