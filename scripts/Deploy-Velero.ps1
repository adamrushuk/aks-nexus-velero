# Deploy Velero

# ! WARNING HELM v3 NOT SUPPORTED!
# https://github.com/vmware-tanzu/helm-charts/issues/7

# Reference
# https://github.com/vmware-tanzu/helm-charts/tree/master/charts/velero#if-using-helm-2-tiller-cluster-admin-permissions
# https://github.com/vmware-tanzu/helm-charts/blob/master/charts/velero/values.yaml
# https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure/blob/master/backupstoragelocation.md
# https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure/blob/master/volumesnapshotlocation.md

# Ensure any errors fail the build
$ErrorActionPreference = "Stop"

# Version info
Write-Output "INFO: Velero Chart currently support Helm v2 CLI. `nTrack issue here: https://github.com/vmware-tanzu/helm-charts/issues/7"
helm version --short


#region Velero
# https://github.com/vmware-tanzu/helm-charts/blob/master/charts/velero/README.md
$message = "[HELM] Installing Velero"
Write-Output "STARTED: $message..."

# Helm 2 - Tiller config
# https://github.com/vmware-tanzu/helm-charts/tree/master/charts/velero#if-using-helm-2-tiller-cluster-admin-permissions
kubectl create sa -n kube-system tiller
kubectl create clusterrolebinding tiller-cluster-admin --clusterrole cluster-admin --serviceaccount kube-system:tiller
helm init --service-account=tiller --wait --upgrade

# Add the Helm repository
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts

# Update your local Helm chart repository cache
helm repo update
helm repo list

# Check if Helm release installed already
$helmReleaseName = "Velero"
$helmDeployedList = helm list --output json | ConvertFrom-Json

if ($helmReleaseName -in $helmDeployedList.Releases.Name) {
    Write-Output "SKIPPING: [$helmReleaseName] already deployed."
} else {
    Write-Output "STARTED: Installing Helm release: [$helmReleaseName]..."

<#
    # Testing
    $env:CREDENTIALS_VELERO = (SEE ./velero/Create-VeleroServicePrinciple.ps1)
    $env:LOCATION = "uksouth"
    $env:VELERO_STORAGE_RG = "rush-rg-velero-dev-001"
    $env:VELERO_STORAGE_ACCOUNT = "rushstbckuksouth001"

    $env:CREDENTIALS_VELERO
    $env:LOCATION
    $env:VELERO_STORAGE_RG
    $env:VELERO_STORAGE_ACCOUNT

    kubectl get namespace
    kubectl create namespace velero
#>

    # https://github.com/vmware-tanzu/helm-charts/tree/master/charts/velero#option-1-cli-commands

    # Helm v2
    # helm install -h
    # helm install [CHART] [flags]
    helm install vmware-tanzu/velero `
        --name velero `
        --namespace velero `
        --set configuration.provider=azure `
        --set credentials.secretContents.cloud=$($env:CREDENTIALS_VELERO) `
        --set configuration.backupStorageLocation.name=azure `
        --set configuration.backupStorageLocation.bucket=velero `
        --set configuration.backupStorageLocation.config.resourceGroup=$($env:VELERO_STORAGE_RG) `
        --set configuration.backupStorageLocation.config.storageAccount=$($env:VELERO_STORAGE_ACCOUNT) `
        --set configuration.volumeSnapshotLocation.name=azure `
        --set configuration.volumeSnapshotLocation.config.resourceGroup=$($env:VELERO_STORAGE_RG) `
        --set image.repository=velero/velero `
        --set image.tag=v1.3.0 `
        --set image.pullPolicy=IfNotPresent `
        --set initContainers[0].name=velero-plugin-for-microsoft-azure `
        --set initContainers[0].image=velero/velero-plugin-for-microsoft-azure:v1.0.1 `
        --set initContainers[0].volumeMounts[0].mountPath=/target `
        --set initContainers[0].volumeMounts[0].name=plugins #`
        # --dry-run --debug

    # [Incorrect] args?
    # --set configuration.backupStorageLocation.config.region=$($env:LOCATION) `
    # --set configuration.volumeSnapshotLocation.config.region=$($env:LOCATION) `

    <#
    # Monitor deployment progress
    kubectl get all -n velero
    kubectl describe pod -n velero
    kubectl get events --sort-by=.metadata.creationTimestamp --namespace velero
    kubectl get events --sort-by=.metadata.creationTimestamp --namespace velero --watch
    kubectl get deployment -n velero --watch
    kubectl logs deployment/velero -n velero -f

    # Cleanup
    helm ls --all velero
    helm del --purge velero --dry-run --debug
    helm del --purge velero
    kubectl delete namespace velero
    #>
}

# Verify
# Show Velero pods
kubectl get pods -o wide --namespace velero

Write-Output "FINISHED: $message.`n"
#endregion
