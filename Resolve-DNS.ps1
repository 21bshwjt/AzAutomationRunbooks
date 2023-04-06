# Runon : Hybrid worker
param
( 
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
        [String] $VMName
)
Resolve-DnsName -Name ($VMName+"."+$env:USERDNSDOMAIN) | Select-Object Name,IPAddress
