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
        owner_name = @{type = 'str'; required = $false }
        state = @{type = 'str'; required = $false; default = 'present'; choices = @('present', 'absent') }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-LowlyDbaSqlServerAuthSpec))
$sqlInstance, $sqlCredential = Get-SqlCredential -Module $module
$database = $module.Params.database
$roleName = $module.Params.role_name
$ownerName = $module.Params.owner_name
$state = $module.Params.state
$checkMode = $module.CheckMode
$module.Result.changed = $false

try {
    # Get database role status
    try {
        $server = Connect-DbaInstance -SqlInstance $sqlInstance -SqlCredential $sqlCredential
        $existingDatabaseRole = $server | Get-DbaDbRole -Database $database -Role $roleName
    }
    catch {
        $module.FailJson("Error checking database role status.", $_.Exception.Message)
    }

    if ($state -eq "absent") {
        if ($null -ne $existingDatabaseRole) {
            try {
                $removeDatabaseRoleSplat = @{
                    SqlInstance = $sqlInstance
                    SqlCredential = $sqlCredential
                    Database = $database
                    Role = $roleName
                    WhatIf = $checkMode
                    EnableException = $true
                    Confirm = $false
                }
                $output = Remove-DbaDbRole @removeDatabaseRoleSplat
                $module.Result.changed = $true
            }
            catch {
                $module.FailJson("Deleting database role [$roleName] failed.", $_)
            }
        }

        $module.ExitJson()
    }
    elseif ($state -eq "present") {
        # Create database role
        if ($null -eq $existingDatabaseRole) {
            try {
                $newDatabaseRoleSplat = @{
                    SqlInstance = $sqlInstance
                    SqlCredential = $sqlCredential
                    Database = $database
                    Role = $roleName
                    WhatIf = $checkMode
                    EnableException = $true
                    Confirm = $false
                }

                if ($null -ne $ownerName) {
                    $newDatabaseRoleSplat.Owner = $ownerName
                }
                $output = New-DbaDbRole @newDatabaseRoleSplat
                $module.Result.changed = $true
            }
            catch {
                $module.FailJson("Creating database role [$roleName] failed.", $_)
            }
        }
        elseif ($existingDatabaseRole.Owner -ne $ownerName) {
            $existingDatabaseRole.Owner = $ownerName
            $existingDatabaseRole.Alter()
            $output = $existingDatabaseRole
            $module.Result.changed = $true
        }
    }

    if ($null -ne $output) {
        $resultData = ConvertTo-SerializableObject -InputObject $output
        $module.Result.data = $resultData
    }
    $module.ExitJson()
}
catch {
    $module.FailJson("Error configuring database role.", $_)
}
