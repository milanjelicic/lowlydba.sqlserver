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
        database = @{type = 'str'; required = $true }
        query = @{type = 'str'; required = $true }
        query_timeout = @{type = 'int'; required = $false; default = 60 }
        messages_to_output = @{type = 'bool'; required = $false; default = $false}
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-LowlyDbaSqlServerAuthSpec))
$sqlInstance, $sqlCredential = Get-SqlCredential -Module $module
$database = $module.Params.database
$query = $module.Params.query
$messagesToOutput = $module.Params.messages_to_output
$queryTimeout = $module.Params.query_timeout
$checkMode = $module.CheckMode

$module.Result.changed = $false

try {
    $invokeQuerySplat = @{
        SqlInstance = $sqlInstance
        SqlCredential = $sqlCredential
        Database = $database
        Query = $query
        QueryTimeout = $queryTimeout
        As = "PSObject"
        MessagesToOutput = $messagesToOutput
        EnableException = $true
    }
    if ($checkMode) {
        $invokeQuerySplat.Add("NoExec", $true)
    }

    $result = Invoke-DbaQuery @invokeQuerySplat
    $completionTime = Get-Date

    $data, $messages = @(), @()

    if ($null -eq $result.Count) {
        $data += $result[0]
    } else {
        if ($result.Count -gt 0) {
            for ($i = 0; $i -lt $result.Count; $i++) {
                if ($messagesToOutput -and $result[$i].GetType().Name -eq "String") {
                    $messages += $result[$i]
                } else {
                    $data += $result[$i]
                }
            }
        }
    }

    $outputSplat = [PSCustomObject]@{
        results = $data
        messages = $messages
        completion_time = $completionTime
    }

    if ($null -ne $outputSplat) {
        $resultData = ConvertTo-SerializableObject -InputObject $outputSplat
        $module.Result.data = $resultData
    }

    $module.Result.changed = $true
    $module.ExitJson()
}
catch {
    $module.FailJson("Executing query failed.", $_)
}
