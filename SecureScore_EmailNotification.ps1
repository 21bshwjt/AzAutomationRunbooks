# ==========================================
# 0. Automation Account Settings
# KB for Creds management: https://learn.microsoft.com/en-us/azure/automation/shared-resources/credentials?tabs=azure-powershell
# ==========================================
$TenantIdVarName = "GraphTenantId"          # Automation Variable
$CredName = "GraphAppCred"           # Automation Credential
$Sender = "<Sender-Email>"      # Must exist in your tenant
$Recipient = "<Receiver_Email>"
$DaysBack = 90                         # Last X days of Secure Scores

# ==========================================
# 1. Get Tenant ID & App Credentials
# ==========================================
$TenantId = Get-AutomationVariable -Name $TenantIdVarName
$Cred = Get-AutomationPSCredential -Name $CredName
$ClientId = $Cred.UserName
$ClientSecret = $Cred.GetNetworkCredential().Password

# ==========================================
# 2. Get OAuth Token for Graph
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

$Headers = @{
    "Authorization" = "Bearer $AccessToken"
    "Content-Type"  = "application/json"
}

# ==========================================
# 3. Get Secure Scores
# ==========================================
$Today = Get-Date
$StartDate = $Today.AddDays(-$DaysBack)
$Uri = "https://graph.microsoft.com/v1.0/security/secureScores"

$SecureScores = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers

# ==========================================
# 4. Convert Secure Scores to HTML Table
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
# ==========================================
$SendUri = "https://graph.microsoft.com/v1.0/users/$Sender/sendMail"
Invoke-RestMethod -Method POST -Uri $SendUri -Headers @{ Authorization = "Bearer $AccessToken" } -Body $EmailPayload -ContentType "application/json"

Write-Output "Email sent successfully."
