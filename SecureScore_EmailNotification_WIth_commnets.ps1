# ==========================================
# 0. Automation Account Settings
# This script authenticates to Microsoft Graph using an app registration
# (client credentials flow), pulls Entra ID Secure Score history for the
# last N days, formats it as an HTML report, and emails it via Graph.
# KB for Creds management: https://learn.microsoft.com/en-us/azure/automation/shared-resources/credentials?tabs=azure-powershell
# ==========================================
$TenantIdVarName = "GraphTenantId"          # Name of the Automation Variable storing the Azure AD Tenant ID
$CredName = "GraphAppCred"           # Name of the Automation Credential storing the App Registration's Client ID/Secret
$Sender = "<Sender-Email>"      # Mailbox used to send the report; must be a valid mailbox in the tenant
$Recipient = "<Receiver_Email>"       # Mailbox that will receive the Secure Score report
$DaysBack = 90                         # How many days of historical Secure Score data to include in the report

# ==========================================
# 1. Get Tenant ID & App Credentials
# Retrieve the tenant ID and app registration credentials from the
# Automation Account's secure storage (not hardcoded in the script).
# ==========================================
$TenantId = Get-AutomationVariable -Name $TenantIdVarName
$Cred = Get-AutomationPSCredential -Name $CredName
$ClientId = $Cred.UserName
$ClientSecret = $Cred.GetNetworkCredential().Password

# ==========================================
# 2. Get OAuth Token for Graph
# Authenticate as the app (client credentials grant) to obtain an
# app-only access token scoped to Microsoft Graph's default permissions.
# ==========================================
$TokenBody = @{
    client_id     = $ClientId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $ClientSecret
    grant_type    = "client_credentials"
}

$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
    -Method POST -Body $TokenBody
$AccessToken = $TokenResponse.access_token

# Standard bearer token header used for all subsequent Graph API calls
$Headers = @{
    "Authorization" = "Bearer $AccessToken"
    "Content-Type"  = "application/json"
}

# ==========================================
# 3. Get Secure Scores
# Call the Graph Security API to pull the tenant's Secure Score history,
# then compute the cutoff date used to filter results to the desired window.
# ==========================================
$Today = Get-Date
$StartDate = $Today.AddDays(-$DaysBack)
$Uri = "https://graph.microsoft.com/v1.0/security/secureScores"

$SecureScores = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

# ==========================================
# 4. Convert Secure Scores to HTML Table
# Filter the returned scores to only those within the DaysBack window,
# sort them newest-first, and build one HTML table row per score entry
# (date, current/max score, percentage, and which services contributed).
# ==========================================
$HTMLRows = foreach ($score in $SecureScores.value | Where-Object { (Get-Date $_.createdDateTime) -ge $StartDate } | Sort-Object { Get-Date $_.createdDateTime } -Descending) {
    "<tr>
        <td>$([datetime]::Parse($score.createdDateTime).ToString('dd-MM-yy'))</td>
        <td>$([math]::Round($score.currentScore,2))</td>
        <td>$([math]::Round($score.maxScore,2))</td>
        <td>$([math]::Round(($score.currentScore / $score.maxScore) * 100, 2))%</td>
        <td>$($score.enabledServices -join ', ')</td>
    </tr>"
} -join "`n"

# Assemble the full HTML email body: inline-styled container, heading,
# intro line, and the table rows generated above.
$HTMLBody = @"
<html>
<head>
  <style>
    body { font-family: Calibri, Arial, Helvetica, sans-serif; background-color: #f9f9f9; padding: 20px; color: #333; }
    .container { background-color: #fff; padding: 25px; border-radius: 10px; box-shadow: 0 3px 6px rgba(0,0,0,0.1); }
    h2 { color: #0078D4; font-weight: 600; }
    p { font-size: 14px; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 14px; }
    th, td { border: 1px solid #ddd; padding: 10px 12px; text-align: left; }
    th { background-color: #0078D4; color: white; font-weight: 600; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    tr:hover { background-color: #e6f0fa; }
  </style>
</head>
<body>
  <div class="container">
    <h2>Entra Secure Score Report</h2>
    <p>Entra ID Secure Score Report – Last 3 Months:</p>
    <table>
      <tr>
        <th>Date</th>
        <th>Current Score</th>
        <th>Max Score</th>
        <th>Score %</th>
        <th>Enabled Services</th>
      </tr>
      $HTMLRows
    </table>
    <p style="margin-top:20px;">Regards,<br/>Graph API Bot</p>
  </div>
</body>
</html>
"@


# ==========================================
# 5. Build Graph Email Payload
# Construct the JSON body for Graph's sendMail API: subject, HTML body,
# recipient, and sender, then serialize it to JSON for the request.
# ==========================================
$EmailPayload = @{
    message         = @{
        subject      = "Entra ID Secure Score Report – Last 3 Months"
        body         = @{
            contentType = "HTML"
            content     = $HTMLBody
        }
        toRecipients = @(
            @{
                emailAddress = @{
                    address = $Recipient
                }
            }
        )
        from         = @{
            emailAddress = @{
                address = $Sender
            }
        }
    }
    saveToSentItems = "false"
} | ConvertTo-Json -Depth 10

# ==========================================
# 6. Send Email via Graph
# POST the payload to the sender mailbox's sendMail endpoint to deliver
# the report. Email is not saved to Sent Items (saveToSentItems = false).
# ==========================================
$SendUri = "https://graph.microsoft.com/v1.0/users/$Sender/sendMail"
Invoke-RestMethod -Method POST -Uri $SendUri -Headers @{ Authorization = "Bearer $AccessToken" } -Body $EmailPayload -ContentType "application/json"

Write-Output "Email sent successfully."
