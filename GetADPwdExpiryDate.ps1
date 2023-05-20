# Run on Hybrid Worker
param
(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] 
    [String] $SamId
)

$PasswordExpired = (Get-ADUser $SamId -Properties PasswordExpired).PasswordExpired
$PasswordNeverExpires = (Get-ADUser $SamId -Properties PasswordNeverExpires).PasswordNeverExpires


If ($PasswordExpired -eq $false) {

    # Get AD Secret Expiry
    $GetUserObj = Get-ADUser -filter { SamAccountName -eq $SamId -and Enabled -eq $True -and PasswordNeverExpires -eq $False } –Properties "SamAccountName", "msDS-UserPasswordExpiryTimeComputed" |
    Select-Object -Property "SamAccountName", @{Name = "ExpiryDate"; Expression = { [datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed") } }
    Write-Output "$SamId password will be expired on: $($GetUserObj.ExpiryDate)"
    if ($PasswordNeverExpires -ne $false) {
        Write-Output "$SamId password will never expire"
    }

}

else {
    Write-Output "$SamId password is already expired!"
}
