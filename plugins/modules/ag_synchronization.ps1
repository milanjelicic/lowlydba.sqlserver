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
        exclude = @{ type = 'list'; elements = 'str' }
        login = @{ type = 'list'; elements = 'str' }
        exclude_login = @{ type = 'list'; elements = 'str' }
        job = @{ type = 'list'; elements = 'str' }
        exclude_job = @{ type = 'list'; elements = 'str' }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-LowlyDbaSqlServerAuthSpec))
$sqlInstance, $sqlCredential = Get-SqlCredential -Module $module
$availabilityGroup = $module.Params.availability_group
$exclude = $module.Params.exclude
$login = $module.Params.login
$excludeLogin = $module.Params.exclude_login
$job = $module.Params.job
$excludeJob = $module.Params.exclude_job
$checkMode = $module.CheckMode
$module.Result.changed = $false

try {
    # Get availability group status
    try {
        $server = Connect-DbaInstance -SqlInstance $sqlInstance -SqlCredential $sqlCredential
        $existingAg = $server | Get-DbaAvailabilityGroup -AvailabilityGroup $availabilityGroup -EnableException
        $existingListener = $existingAg.AvailabilityGroupListeners
        $existingAgReplicas = Get-DbaAgReplica -SqlInstance $existingListener.Name -SqlCredential $sqlCredential -AvailabilityGroup $availabilityGroup

        $primaryNode = ($existingAgReplicas | Where-Object role -eq 'Primary').Name
        $secondaryNode = ($existingAgReplicas | Where-Object role -eq 'Secondary').Name
    }
    catch {
        $module.FailJson("Error checking availability group status.", $_.Exception.Message)
    }

    $syncAvailabilityGroupSplat = @{
        Primary = $primaryNode
        PrimarySqlCredential = $sqlCredential
        Secondary = $secondaryNode
        SecondarySqlCredential = $sqlCredential
        AvailabilityGroup = $availabilityGroup
        Exclude = $exclude
        Login = $login
        ExcludeLogin = $excludeLogin
        Job = $job
        ExcludeJob = $excludeJob
        WhatIf = $checkMode
        EnableException = $true
        Confirm = $false
    }

    try {
        $output = Sync-DbaAvailabilityGroup @syncAvailabilityGroupSplat
    }
    catch {
        $module.FailJson("Synchronizing availability group [$availabilityGroup] failed. [$_].")
    }

    if ($null -ne $output) {
        $resultData = ConvertTo-SerializableObject -InputObject $output
        $module.Result.data = $resultData
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Error synchronizing availability group.", $_)
}
