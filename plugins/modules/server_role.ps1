#!powershell
# -*- coding: utf-8 -*-

# (c) 2022, John McCall (@lowlydba)
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
        login_name = @{type = 'str'; required = $false }
        owner_name = @{type = 'str'; required = $false; default = 'sa' }
        state = @{type = 'str'; required = $false; default = 'present'; choices = @('present', 'absent') }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-LowlyDbaSqlServerAuthSpec))
$sqlInstance, $sqlCredential = Get-SqlCredential -Module $module
$roleName = $module.Params.role_name
$loginName = $module.Params.login_name
$ownerName = $module.Params.owner_name
$state = $module.Params.state
$checkMode = $module.CheckMode
$module.Result.changed = $false

try {
    # Get server role status
    try {
        $server = Connect-DbaInstance -SqlInstance $sqlInstance -SqlCredential $sqlCredential
        $existingServerRole = $server | Get-DbaServerRole -ServerRole $roleName
    }
    catch {
        $module.FailJson("Error checking server role status.", $_.Exception.Message)
    }

    if ($state -eq "absent") {
        $databases = $existingAg.AvailabilityDatabases | Select-Object Name
        if ($databases.Name -contains $database) {
            try {
                $removeServerRoleSplat = @{
                    SqlInstance = $sqlInstance
                    SqlCredential = $sqlCredential
                    ServerRole = $roleName
                    WhatIf = $checkMode
                    EnableException = $true
                    Confirm = $false
                }
                $output = Remove-DbaServerRole @removeServerRoleSplat
                if ($output.Status -eq "Success") {
                    $module.Result.changed = $true
                }
                elseif ($output.Status -ne "Success") {
                    $module.FailJson("Server role [$roleName] was not removed. " + $output.Status)
                }
            }
            catch {
                $module.FailJson("Deleting server role [$roleName] failed.", $_)
            }
        }

        $module.ExitJson()
    }
    elseif ($state -eq "present") {
        # Create server role
        if ($null -eq $existingServerRole) {
            try {
                $newServerRoleSplat = @{
                    SqlInstance = $sqlInstance
                    SqlCredential = $sqlCredential
                    ServerRole = $roleName
                    WhatIf = $checkMode
                    EnableException = $true
                    Confirm = $false
                }

                if ($null -ne $ownerName) {
                    $newServerRoleSplat.Owner = $ownerName
                }
                $output = New-DbaServerRole @newServerRoleSplat
                $module.Result.changed = $true
            }
            catch {
                $module.FailJson("Creating server role [$roleName] failed.", $_)
            }
        }

        if ($null -ne $loginName) {
            try {
                $invokeQuerySplat = @{
                    SqlInstance = $sqlInstance
                    SqlCredential = $sqlCredential
                    Query = "GRANT ALTER ON LOGIN::[$loginName] TO [$roleName];"
                    MessagesToOutput = $true
                    EnableException = $true
                }
                $invokeQueryOutput = Invoke-DbaQuery @invokeQuerySplat
                $module.Result.changed = $true
            }
            catch {
                $module.FailJson("Granting ALTER on role [$roleName] to login [$loginName] failed.", $_)
            }
        }
    }

    if ($null -ne $output) {
        $resultData = ConvertTo-SerializableObject -InputObject $output
        $module.Result.data = $resultData
    }
    elseif ($null -ne $invokeQueryOutput) {
        $resultData = ConvertTo-SerializableObject -InputObject $invokeQueryOutput
        $module.Result.data = $resultData
    }
    $module.ExitJson()
}
catch {
    $module.FailJson("Error configuring server role.", $_)
}
