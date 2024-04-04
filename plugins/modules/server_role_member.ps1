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
        role_name = @{type = 'str'; required = $true }
        login_name = @{type = 'str'; required = $true }
        state = @{type = 'str'; required = $false; default = 'present'; choices = @('present', 'absent') }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-LowlyDbaSqlServerAuthSpec))
$sqlInstance, $sqlCredential = Get-SqlCredential -Module $module
$roleName = $module.Params.role_name
$loginName = $module.Params.login_name
$state = $module.Params.state
$checkMode = $module.CheckMode
$module.Result.changed = $false

try {
    # Get server role member status
    try {
        $server = Connect-DbaInstance -SqlInstance $sqlInstance -SqlCredential $sqlCredential
        $existingServerRoleMembers = @()
        $server | Get-DbaServerRoleMember -ServerRole $roleName | ForEach-Object { $existingServerRoleMembers += $_.Name }
    }
    catch {
        $module.FailJson("Error checking server role member status.", $_.Exception.Message)
    }

    if ($state -eq "absent") {
        if ($null -ne $existingServerRoleMembers -and $existingServerRoleMembers -contains $loginName) {
            try {
                $removeServerRoleMemberSplat = @{
                    SqlInstance = $sqlInstance
                    SqlCredential = $sqlCredential
                    ServerRole = $roleName
                    Login = $loginName
                    WhatIf = $checkMode
                    EnableException = $true
                    Confirm = $false
                }
                $output = Remove-DbaServerRoleMember @removeServerRoleMemberSplat
                $existingServerRoleMembers = $existingServerRoleMembers | Where-Object { $_ -ne $loginName }
                $module.Result.changed = $true
            }
            catch {
                $module.FailJson("Deleting member [$loginName] from role [$roleName] failed.", $_)
            }
        }
    }
    elseif ($state -eq "present") {
        # Create server role
        if ($null -eq $existingServerRoleMembers -or $existingServerRoleMembers -notcontains $loginName) {
            try {
                $addServerRoleMemberSplat = @{
                    SqlInstance = $sqlInstance
                    SqlCredential = $sqlCredential
                    ServerRole = $roleName
                    Login = $loginName
                    WhatIf = $checkMode
                    EnableException = $true
                    Confirm = $false
                }

                $output = Add-DbaServerRoleMember @addServerRoleMemberSplat
                $existingServerRoleMembers += $loginName
                $module.Result.changed = $true
            }
            catch {
                $module.FailJson("Adding member [$loginName] to role [$roleName] failed.", $_)
            }
        }
    }

    $output = [PSCustomObject]@{
        instance = $sqlInstance
        members = $existingServerRoleMembers
        role = $roleName
    }

    if ($null -ne $output) {
        $resultData = ConvertTo-SerializableObject -InputObject $output
        $module.Result.data = $resultData
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Error configuring server role member.", $_)
}
