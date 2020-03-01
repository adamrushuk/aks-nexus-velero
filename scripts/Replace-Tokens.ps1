# Replace tokens
param (
    $targetFilePattern = './terraform/*.tf',
    $tokenPrefix = '__',
    $tokenSuffix = '__'
)

# Ensure any errors fail the build
$ErrorActionPreference = "Stop"

$message = "Replacing tokens in Environment variables"
Write-Output "`nSTARTED: $message..."

# Prepare env vars
$envVarHash = @{ }
foreach ($envvar in (Get-ChildItem env:)) {
    $envVarHash.Add("$($tokenPrefix)$($envvar.Name)$($tokenSuffix)", $envvar.Value)
}

if ($env:CI_DEBUG -eq "true") {
    # Write warning to workflow
    # https://help.github.com/en/actions/reference/development-tools-for-github-actions#set-a-warning-message-warning
    # ::warning file={name},line={line},col={col}::{message}
    echo "::warning ::CI_DEBUG is 'true'...showing env vars which may contain sensitive information"

    $envVarHash.GetEnumerator() | Sort-Object Name
}

# Get files
$targetFiles = (Get-ChildItem -Path $targetFilePattern)

# Replace tokens
foreach ($targetFile in $targetFiles) {
    foreach ($item in $envVarHash.GetEnumerator()) {
        ((Get-Content -Path $targetFile -Raw) -replace $item.key, $item.value) | Set-Content -Path $targetFile
    }
}

Write-Output "FINISHED: $message."
