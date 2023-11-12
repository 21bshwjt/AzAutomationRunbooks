<#
###=>Actice Directory Account Status<=###
# Enabled/Disabled
# Password Expired.
# Password Expiry Date
# PasswordNeverExpires
# Lockout Status
# Exist or not.
#>
param
(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] 
    [String] $SamId
)
$ErrorActionPreference = 'SilentlyContinue'
$PasswordExpired = (Get-ADUser $SamId -Properties PasswordExpired).PasswordExpired
$PasswordNeverExpires = (Get-ADUser $SamId -Properties PasswordNeverExpires).PasswordNeverExpires
$AccountEnabled = (Get-ADUser $SamId -Properties Enabled).Enabled
$AccountExistorNot = $null -ne ([ADSISearcher] "(sAMAccountName=$SamId)").FindOne()

If ($AccountExistorNot -eq $true) {
    if ($PasswordNeverExpires -ne $false) {              
        Write-Output "$SamId password will never expire."
        Exit
    }

    # Validate Account is Enabled.
    If ($AccountEnabled -eq $true) {
        # Validate Password is not expired
        If ($PasswordExpired -eq $false) {

            # Get AD Secret Expiry
            $GetUserObj = Get-ADUser -filter { SamAccountName -eq $SamId -and Enabled -eq $True -and PasswordNeverExpires -eq $False } –Properties "SamAccountName", "msDS-UserPasswordExpiryTimeComputed", "UserPrincipalName", "Enabled", "LockedOut", "DistinguishedName" |
            Select-Object -Property "SamAccountName", @{Name = "ExpiryDate"; Expression = { [datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed") } }, "UserPrincipalName", "Enabled", "LockedOut", "DistinguishedName"
            Write-Output "$SamId password will be expired on: $($GetUserObj.ExpiryDate)"
            Write-Output "<=====================>"
            Write-Output $GetUserObj

        }

        else {
            Write-Output "$SamId password is already expired!"
        }
    }
    else {
        Write-Output "$SamId is in Disabled state"
    }
}
else {
    Write-Output "$SamId does not exist in $env:USERDNSDOMAIN Domain"
}
