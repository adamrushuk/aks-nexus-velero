# Get Storage Account key and update GitHub Workflow

#region Vars
# Set preferences
$VerbosePreference = if ($env:CI_DEBUG -eq "true") { "Continue" } else { "SilentlyContinue" }
# Ensure any PowerShell errors fail the build (try/catch wont work for non-PowerShell CLI commands)
$ErrorActionPreference = "Stop"
#endregion



#region Storage Account Key
$taskMessage = "Getting Storage Account Key"
Write-Verbose "STARTED: $taskMessage..."

# Run CLI command
$storageKey = (az storage account keys list --resource-group $env:TERRAFORM_STORAGE_RG --account-name $env:TERRAFORM_STORAGE_ACCOUNT --query [0].value -o tsv)

# Error handling
if (-not $storageKey) {
    Write-Error "ERROR: $taskMessage." -ErrorAction 'Continue'
    throw $_
} else {
    # Set env var
    # https://help.github.com/en/actions/reference/development-tools-for-github-actions#set-an-environment-variable-set-env
    # ::set-env name={name}::{value}
    echo "::set-env name=STORAGE_KEY::$storageKey"

    # mask sensitive env var value
    $STORAGE_KEY = $storageKey
    echo "::add-mask::$STORAGE_KEY"

    Write-Verbose "FINISHED: $taskMessage."
}
#endregion
