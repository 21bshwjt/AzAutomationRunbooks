# Contributing

Thanks for helping make these runbooks better! 🎉

## Ways to contribute

- 🐛 **Report a bug** — open a [bug report](../../issues/new?template=bug_report.yml)
- 💡 **Suggest a runbook** — open a [runbook request](../../issues/new?template=runbook_request.yml)
- 🛠️ **Submit a runbook or fix** — open a pull request

## Adding a runbook

1. Fork the repo and create a branch: `git checkout -b feature/my-runbook`.
2. Add your `.ps1` file at the repo root, following the existing style:
   - A header comment that explains what it does and where it runs:
     ```powershell
     <#
     # Runon : Azure          (or: Hybrid worker)
     # Purpose : Email a report of ...
     # Permissions : Reader on subscription, Mail.Send
     #>
     ```
   - Authenticate with an Automation **connection**, **credential/variable assets**, or **Managed Identity** — never hardcode secrets.
   - Use `<Placeholder>` values for anything environment-specific (`<Subscription_ID>`, `<RG_Name>`, `<KeyVault>`).
   - Wrap the login in `try/catch` and `throw` on failure so the job is marked **Failed**.
3. Run the linter locally:
   ```powershell
   Install-Module PSScriptAnalyzer -Scope CurrentUser
   Invoke-ScriptAnalyzer -Path .\MyRunbook.ps1 -Severity Error, Warning
   ```
4. Test it in the Automation Account **Test pane** (or on a Hybrid Worker).
5. Add a row to the **Runbook catalog** table in [README.md](README.md).
6. Open a pull request and fill in the checklist.

## ⚠️ Before you push

Double-check that your commit contains **no** tenant IDs, subscription IDs, client secrets, certificate thumbprints, or real email addresses.
