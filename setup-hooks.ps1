# PowerShell script to install the Git pre-push hook

# Check if the .git/hooks directory exists
if (-not (Test-Path ".git/hooks")) {
    Write-Host "The .git/hooks directory was not found. Are you sure you are in the root of a Git repository?"
    exit 1
}

# Read the file content and ensure LF endings
$content = Get-Content -Path "hooks\pre-push" -Raw -Encoding UTF8
$content = $content -replace "`r`n", "`n" -replace "`r", "`n"
Set-Content -Path ".git\hooks\pre-push" -Value $content -NoNewline -Encoding UTF8

Write-Host "Pre-push hook installed successfully."
