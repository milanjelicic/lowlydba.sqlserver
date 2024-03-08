#!powershell
# -*- coding: utf-8 -*-

# (c) 2024, Milan Jelicic (@milanjelicic)
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
$agName = $module.Params.availability_group
$module.Result.changed = $false

try {
    $availabilityGroup = Get-DbaAvailabilityGroup -SqlInstance $sqlInstance -AvailabilityGroup $agName -SqlCredential $sqlCredential

    if ($null -ne $availabilityGroup) {
        $resultData = $availabilityGroup.AvailabilityReplicas | ForEach-Object { $_.Name }
        $module.Result.data = $resultData
    }
    $module.ExitJson()
}
catch {
    $module.FailJson("Error getting ${ag_name} replicas for ${sqlInstance} instance.", $_)
}
