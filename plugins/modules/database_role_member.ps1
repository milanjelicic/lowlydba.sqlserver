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
        role_name = @{type = 'str'; required = $true }
        user_name = @{type = 'str'; required = $true }
        state = @{type = 'str'; required = $false; default = 'present'; choices = @('present', 'absent') }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-LowlyDbaSqlServerAuthSpec))
$sqlInstance, $sqlCredential = Get-SqlCredential -Module $module
$database = $module.Params.database
$roleName = $module.Params.role_name
$userName = $module.Params.user_name
$state = $module.Params.state
$checkMode = $module.CheckMode
$module.Result.changed = $false

try {
    # Get database role member status
    try {
        $server = Connect-DbaInstance -SqlInstance $sqlInstance -SqlCredential $sqlCredential
        $existingDbRoleMembers = $server | Get-DbaDbRoleMember -Database $database -Role $roleName | Select-Object -ExpandProperty UserName
    }
    catch {
        $module.FailJson("Error checking database role member status.", $_.Exception.Message)
    }

    if ($state -eq "absent") {
        # Remove member from database role
        if ($null -ne $existingDbRoleMembers -and $existingDbRoleMembers -contains $userName) {
            try {
                $removeDatabaseRoleMemberSplat = @{
                    SqlInstance = $sqlInstance
                    SqlCredential = $sqlCredential
                    Database = $database
                    Role = $roleName
                    User = $userName
                    WhatIf = $checkMode
                    EnableException = $true
                    Confirm = $false
                }
                Remove-DbaDbRoleMember @removeDatabaseRoleMemberSplat
                $existingDbRoleMembers = $existingDbRoleMembers | Where-Object { $_ -ne $userName }
                $module.Result.changed = $true
            }
            catch {
                $module.FailJson("Deleting member [$userName] from role [$roleName] failed.", $_)
            }
        }
    }
    elseif ($state -eq "present") {
        # Add member to database role
        if ($null -eq $existingDbRoleMembers -or $existingDbRoleMembers -notcontains $userName) {
            try {
                $addDatabaseRoleMemberSplat = @{
                    SqlInstance = $sqlInstance
                    SqlCredential = $sqlCredential
                    Database = $database
                    Role = $roleName
                    User = $userName
                    WhatIf = $checkMode
                    EnableException = $true
                    Confirm = $false
                }

                Add-DbaDbRoleMember @addDatabaseRoleMemberSplat
                $existingDbRoleMembers += $userName
                $module.Result.changed = $true
            }
            catch {
                $module.FailJson("Adding member [$userName] to role [$roleName] failed.", $_)
            }
        }
    }

    $output = [PSCustomObject]@{
        Database = $database
        Members = $existingDbRoleMembers
        Role = $roleName
    }

    if ($null -ne $output) {
        $resultData = ConvertTo-SerializableObject -InputObject $output
        $module.Result.data = $resultData
    }
    $module.ExitJson()
}
catch {
    $module.FailJson("Error configuring database role member.", $_)
}
