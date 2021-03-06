# Ansible Notes

Notes on using Ansible for post-deployment configuration.

> **IMPORTANT**
> Most of the other code examples use PowerShell and CLIs that run on *all* platforms, but as Ansible won't run on
> Windows, Windows users will have to
> [install Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10).

## Contents

- [Ansible Notes](#ansible-notes)
  - [Contents](#contents)
  - [Prereqs](#prereqs)
  - [Running Ansible](#running-ansible)

## Prereqs

Before the Ansible playbook can be run, follow the steps below:

1. From the default bash shell in WSL, enter into PowerShell 7:

    ```powershell
    # [OPTIONAL] Install PowerShell 7 on any Linux distro
    sudo wget -O - https://aka.ms/install-powershell.sh | sudo bash

    # Start PowerShell
    pwsh
    ```

1. Import the AKS Cluster credentials after updating the vars to reflect your environment:

    ```powershell
    # Vars
    $prefix = "rush"
    $aksClusterName = "$($prefix)-aks-001"
    $aksClusterResourceGroupName = "$($prefix)-rg-aks-dev-001"

    # Login to Azure
    az login

    # [OPTIONAL] Install kubectl
    az aks install-cli

    # AKS Cluster credentials
    az aks get-credentials --resource-group $aksClusterResourceGroupName --name $aksClusterName --overwrite-existing --admin

    # [OPTIONAL] View AKS Dashboard
    az aks browse --resource-group $aksClusterResourceGroupName --name $aksClusterName
    ```

1. Get the auto-generated admin password from within the Nexus container:

    ```powershell
    # Get pod name
    $podName = kubectl get pod --namespace nexus -l app.kubernetes.io/name=sonatype-nexus -o jsonpath="{.items[0].metadata.name}"

    # Get admin password from pod
    # NOTE: "/nexus-data/admin.password" is deleted after the admin password is changed
    $adminPassword = kubectl exec --namespace nexus -it $podName cat /nexus-data/admin.password
    echo $adminPassword
    ```

1. Set environment variables for passwords:

    ```powershell
    $env:AUTOGENERATED_ADMIN_PASSWORD = $adminPassword
    $env:NEW_ADMIN_PASSWORD = "<NEW_ADMIN_PASSWORD>"
    ```

## Running Ansible

After the prereqs steps have been completed, run the Ansible Playbook:

1. Move into the `ansible` folder:

    ```powershell
    cd ansible
    ```

1. Get the nexus hostname:

    ```powershell
    # Set vars
    $nexusHost = kubectl get ingress ingress --namespace ingress -o jsonpath="{.spec.rules[0].host}"
    $nexusBaseUrl = "https://$nexusHost"
    ```

1. Run the Ansible Playbook:

    ```powershell
    ansible-playbook site.yml --extra-vars "api_base_uri=$nexusBaseUrl"
    ```
