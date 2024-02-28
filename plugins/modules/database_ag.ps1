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
        username = @{type = 'str'; required = $false }
        password = @{type = 'str'; required = $false; no_log = $true }
        enabled = @{type = 'bool'; required = $false; default = $true }
        force = @{type = 'bool'; required = $false; default = $false }
        state = @{type = 'str'; required = $false; default = 'present'; choices = @('present', 'absent') }
    }
    required_together = @(
        , @('username', 'password')
    )
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-LowlyDbaSqlServerAuthSpec))
$sqlInstance, $sqlCredential = Get-SqlCredential -Module $module
if ($null -ne $Module.Params.username) {
    [securestring]$secPassword = ConvertTo-SecureString $Module.Params.password -AsPlainText -Force
    [pscredential]$credential = New-Object System.Management.Automation.PSCredential ($Module.Params.username, $secPassword)
}
$enabled = $module.Params.enabled
$force = $module.Params.force
$checkMode = $module.CheckMode
$module.Result.changed = $false

try {
    # Get availability group status
    try {
        $server = Connect-DbaInstance -SqlInstance $sqlInstance -SqlCredential $sqlCredential
        $existingAg = $server | Get-DbaAvailabilityGroup -EnableException | Select-Object -ExpandProperty AvailabilityGroup
        $existingListener = $server | Get-DbaAvailabilityGroup -EnableException | Select-Object -ExpandProperty AvailabilityGroupListeners
        $existingAgReplicas = Get-DbaAgReplica -SqlInstance $existingListener.Name -SqlCredential $sqlCredential -AvailabilityGroup $existingAg

        $primaryNode = ($agReplicas | Where-Object role -eq 'Primary').Name
        $secondaryNode = ($agReplicas | Where-Object role -eq 'Secondary').Name
    }
    catch {
        $module.FailJson("Error checking availability group status.", $_.Exception.Message)
    }

    if ($state -eq "absent") {
        $databases = $existingAg.AvailabilityDatabases | Select-Object Name
        if ($databases.Name -contains $database) {
            try {
                $output = Remove-DbaAgDatabase -SqlInstance $primaryNode - SqlCredential $sqlCredential `
                    -AvailabilityGroup $existingAg `
                    -Database $database `
                    -EnableException -Confirm:$false

                if ($output.Status -eq "Removed") {
                    $module.Result.changed = $true
                }
                elseif ($output.Status -ne "Removed") {
                    $module.FailJson("Database [$database] was not removed from AG [$existingAg]. " + $droppedDatabase.Status)
                }
            }
            catch {
                $module.FailJson("An exception occurred while trying to remove database [$database] from AG [$existingAg].", $_)
            }
        }

        $module.ExitJson()
    }
    elseif ($state -eq "present") {
        try {
            $output = Add-DbaAgDatabase -SqlInstance $primaryNode - SqlCredential $sqlCredential `
                -Secondary $secondaryNode -SecondarySqlCredential $sqlCredential `
                -AvailabilityGroup $existingAg `
                -Database $database `
                -EnableException -Confirm:$false
            $module.Result.changed = $true
        }
        catch {
            $module.FailJson("An exception occurred while trying to add database [$database] to AG [$existingAg].", $_)
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
