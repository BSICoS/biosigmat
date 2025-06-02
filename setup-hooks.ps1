# PowerShell script to install the Git pre-push hook

# Check if the .git/hooks directory exists
if (-not (Test-Path ".git/hooks")) {
    Write-Host "The .git/hooks directory was not found. Are you sure you are in the root of a Git repository?"
    exit 1
}

# Copy the pre-push hook from the hooks directory
Copy-Item -Path "hooks\pre-push" -Destination ".git\hooks\pre-push" -Force

# In Windows, making a file executable isn't needed. But we ensure LF line endings (optional)
(Get-Content ".git\hooks\pre-push") | Set-Content -NoNewline ".git\hooks\pre-push"

Write-Host "Pre-push hook installed successfully."
