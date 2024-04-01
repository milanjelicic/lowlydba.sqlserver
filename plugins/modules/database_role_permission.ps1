#!powershell
# -*- coding: utf-8 -*-

# (c) 2024, Daniel Gutierrez (@gutizar)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.lowlydba.sqlserver.plugins.module_utils._SqlServerUtils
#Requires -Modules @{ ModuleName="dbatools"; ModuleVersion="2.0.0" }

$ErrorActionPreference = "Stop"

$permissionList = @(
    'ALTER',
    'CONTROL',
    'DELETE',
    'EXECUTE',
    'INSERT',
    'RECEIVE',
    'REFERENCES',
    'SELECT',
    'TAKE OWNERSHIP',
    'UPDATE',
    'VIEW CHANGE TRACKING',
    'VIEW DEFINITION'
)

# Get Csharp utility module
$spec = @{
    supports_check_mode = $true
    options = @{
        database = @{type = 'str'; required = $true }
        role_name = @{type = 'str'; required = $true }
        permission = @{type = 'str'; required = $true; choices = $permissionList}
        action = @{type = 'str'; required = $false; default = 'grant'; choices = @('grant', 'deny', 'revoke') }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-LowlyDbaSqlServerAuthSpec))
$sqlInstance, $sqlCredential = Get-SqlCredential -Module $module
$database = $module.Params.database
$roleName = $module.Params.role_name
$permission = $module.Params.permission
$action = $module.Params.action
$module.Result.changed = $false

try {
    # Fetch existing permission in database role.
    try {
        $server = Connect-DbaInstance -SqlInstance $sqlInstance -SqlCredential $sqlCredential
        $existingPermissionQuery = @(
            "SELECT pe.permission_name, pe.state_desc, pe.class_desc, OBJECT_NAME(pe.major_id) AS object_name"
            "FROM sys.database_principals dp"
            "JOIN sys.database_permissions pe ON pe.grantee_principal_id = dp.principal_id"
            "WHERE dp.name = '$roleName' AND pe.permission_name = '$permission'"
        ) -join " "
        $existingPermission = $server | Invoke-DbaQuery -Database $database -Query $existingPermissionQuery -As PSObject
    }
    catch {
        $module.FailJson("Error checking database role permission status.", $_.Exception.Message)
    }

    if ($action -eq "revoke") {
        # Revoke permission.
        if ($null -ne $existingPermission) {
            try {
                $revokePermissionSplat = @{
                    SqlInstance = $sqlInstance
                    SqlCredential = $sqlCredential
                    Database = $database
                    Query = "REVOKE $permission FROM $roleName"
                    MessagesToOutput = $true
                    EnableException = $true
                }
                $output = Invoke-DbaQuery @revokePermissionSplat
                $module.Result.changed = $true
            }
            catch {
                $module.FailJson("Revoking permission [$permission] from database role [$roleName] failed.", $_)
            }
        }
    }
    elseif ($action -eq "deny") {
        # Deny permission from role.
        if ($null -eq $existingPermission -or $existingPermission.state_desc -eq "GRANT") {
            try {
                $denyPermissionSplat = @{
                    SqlInstance = $sqlInstance
                    SqlCredential = $sqlCredential
                    Database = $database
                    Query = "DENY $permission TO $roleName"
                    MessagesToOutput = $true
                    EnableException = $true
                }
                $output = Invoke-DbaQuery @denyPermissionSplat
                $module.Result.changed = $true
            }
            catch {
                $module.FailJson("Denying permission [$permission] to database role [$roleName] failed.", $_)
            }
        }
    }
    elseif ($action -eq "grant") {
        if ($null -eq $existingPermission -or $existingPermission.state_desc -eq "DENY") {
            try {
                $grantPermissionSplat = @{
                    SqlInstance = $sqlInstance
                    SqlCredential = $sqlCredential
                    Database = $database
                    Query = "GRANT $permission TO $roleName"
                    MessagesToOutput = $true
                    EnableException = $true
                }
                $output = Invoke-DbaQuery @grantPermissionSplat
                $module.Result.changed = $true
            }
            catch {
                $module.FailJson("Granting permission [$permission] to database role [$roleName] failed.", $_)
            }
        }
    }

    if ($null -ne $output) {
        $resultData = ConvertTo-SerializableObject -InputObject $output
        $module.Result.data = $resultData
    }
    $module.ExitJson()
}
catch {
    $module.FailJson("Error modifying permissions for database role.", $_)
}
