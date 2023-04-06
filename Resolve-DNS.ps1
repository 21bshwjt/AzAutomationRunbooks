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
