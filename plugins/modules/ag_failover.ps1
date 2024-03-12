#!powershell
# -*- coding: utf-8 -*-

# (c) 2024, Daniel Gutierrez (@gutizar)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.lowlydba.sqlserver.plugins.module_utils._SqlServerUtils
#Requires -Modules @{ ModuleName="dbatools"; ModuleVersion="2.0.0" }

$ErrorActionPreference = "Stop"

# Get Csharp utility module
$spec = @{
    supports_check_mode = $true
    options = @{
        availability_group = @{type = 'str'; required = $true }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-LowlyDbaSqlServerAuthSpec))
$sqlInstance, $sqlCredential = Get-SqlCredential -Module $module
$availabilityGroup = $module.Params.availability_group
$checkMode = $module.CheckMode

$module.Result.changed = $false

try {
    # Get availability group status
    try {
        $server = Connect-DbaInstance -SqlInstance $sqlInstance -SqlCredential $sqlCredential
        $existingAg = $server | Get-DbaAvailabilityGroup -AvailabilityGroup $availabilityGroup -EnableException
        $existingListener = $existingAg.AvailabilityGroupListeners
        $existingAgReplicas = Get-DbaAgReplica -SqlInstance $existingListener.Name -SqlCredential $sqlCredential -AvailabilityGroup $availabilityGroup

        $secondaryNode = ($existingAgReplicas | Where-Object role -eq 'Secondary').Name
    }
    catch {
        $module.FailJson("Error checking availability group status.", $_)
    }

    if ($null -ne $existingAg) {
        try {
            $invokeAgFailoverSplat = @{
                SqlInstance = $secondaryNode
                SqlCredential = $sqlCredential
                AvailabilityGroup = $availabilityGroup
                WhatIf = $checkMode
                EnableException = $true
                Confirm = $false
            }

            $output = Invoke-DbaAgFailover @invokeAgFailoverSplat
            $module.Result.changed = $true
        }
        catch {
            $module.FailJson("An exception occurred while trying to perform a failover for [$availabilityGroup].", $_)
        }
    }

    if ($null -ne $output) {
        $resultData = ConvertTo-SerializableObject -InputObject $output
        $module.Result.data = $resultData
    }
    $module.ExitJson()
}
catch {
    $module.FailJson("Executing nonquery failed.", $_)
}
