# Runon : Hybrid worker
param
(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
        [String] $SAMID
)
Write-Output "==> Get An AD User"
Get-ADUser $SAMID | Select-object SamAccountName,DistinguishedName,Enabled
Write-Output "<===============>"
