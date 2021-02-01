#! /usr/bin/env bash
#
# installs and runs tflint with tflint-ruleset-azurerm plugin

# ensure strict mode and predictable failure
set -euo pipefail
trap "echo 'error: Script failed: see failed command above'" ERR

# vars
export TFLINT_LOG=debug
# DISABLED_RULES=("azurerm_log_analytics_workspace_invalid_retention_in_days")
DISABLED_RULES=()
# Set local vars from env var, with default fallbacks
TFLINT_VERSION="${TFLINT_VERSION:-v0.23.1}"
TFLINT_RULESET_AZURERM_VERSION="${TFLINT_RULESET_AZURERM_VERSION:-v0.7.0}"

message="Downloading tflint ($TFLINT_VERSION) and azurerm plugin ($TFLINT_RULESET_AZURERM_VERSION)"
echo "STARTED: $message..."

# download tflint
curl -L "https://github.com/terraform-linters/tflint/releases/download/$TFLINT_VERSION/tflint_linux_amd64.zip" -o tflint.zip && unzip tflint.zip && rm tflint.zip

# download tflint-ruleset-azurerm plugin
curl -L "https://github.com/terraform-linters/tflint-ruleset-azurerm/releases/download/$TFLINT_RULESET_AZURERM_VERSION/tflint-ruleset-azurerm_linux_amd64.zip" -o tflint-ruleset-azurerm_linux_amd64.zip && unzip tflint-ruleset-azurerm_linux_amd64.zip && rm tflint-ruleset-azurerm_linux_amd64.zip

# move tflint-ruleset-azurerm plugin to correct path
install -D -m 777 tflint-ruleset-azurerm ./.tflint.d/plugins/tflint-ruleset-azurerm

echo "FINISHED: $message."

# check versions
./tflint --version

# create tflint config
cat > .tflint.hcl << EOF
plugin "azurerm" {
    enabled = true
}
EOF
cat .tflint.hcl

# add dynamic flags
TF_FLAGS=("$TF_WORKING_DIR")

if [ ${#DISABLED_RULES[@]} -gt 0 ]; then
    echo "Adding DISABLED_RULES..."

    # expand array for disabled rules
    TF_FLAGS+=(--disable-rule="${DISABLED_RULES[*]}")
fi

# run tflint
# TFLINT_LOG=debug ./tflint "$TF_WORKING_DIR" --disable-rule="${DISABLED_RULES[*]}"
./tflint "${TF_FLAGS[@]}"
