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
        database = @{type = 'str'; required = $true }
        availability_group = @{type = 'str'; required = $true }
        state = @{type = 'str'; required = $false; default = 'present'; choices = @('present', 'absent') }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-LowlyDbaSqlServerAuthSpec))
$sqlInstance, $sqlCredential = Get-SqlCredential -Module $module
$database = $module.Params.database
$availabilityGroup = $module.Params.availability_group
$state = $module.Params.state
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
        $module.FailJson("Error checking availability group status.", $_)
    }

    if ($state -eq "absent") {
        $databases = $existingAg.AvailabilityDatabases | Select-Object Name
        if ($databases.Name -contains $database) {
            try {
                $removeAgDatabaseSplat = @{
                    SqlInstance = $primaryNode
                    SqlCredential = $sqlCredential
                    AvailabilityGroup = $availabilityGroup
                    Database = $database
                    WhatIf = $checkMode
                    EnableException = $true
                    Confirm = $false
                }
                $output = Remove-DbaAgDatabase @removeAgDatabaseSplat

                if ($output.Status -eq "Removed") {
                    $module.Result.changed = $true
                }
                elseif ($output.Status -ne "Removed") {
                    $module.FailJson("Database [$database] was not removed from AG [$availabilityGroup]. " + $output.Status)
                }
            }
            catch {
                $module.FailJson("An exception occurred while trying to remove database [$database] from AG [$availabilityGroup].", $_)
            }
        }

        $module.ExitJson()
    }
    elseif ($state -eq "present") {
        try {
            $addAgDatabaseSplat = @{
                SqlInstance = $primaryNode
                SqlCredential = $sqlCredential
                Secondary = $secondaryNode
                SecondarySqlCredential = $sqlCredential
                AvailabilityGroup = $availabilityGroup
                Database = $database
                WhatIf = $checkMode
                EnableException = $true
                Confirm = $false
            }
            Add-DbaAgDatabase @addAgDatabaseSplat
            $output = $null
            $module.Result.changed = $true
        }
        catch {
            $module.FailJson("An exception occurred while trying to add database [$database] to AG [$availabilityGroup].", $_)
        }
    }

    if ($null -ne $output) {
        $resultData = ConvertTo-SerializableObject -InputObject $output
        $module.Result.data = $resultData
    }
    $module.ExitJson()
}
catch {
    $module.FailJson("Error configuring AG database.", $_)
}
