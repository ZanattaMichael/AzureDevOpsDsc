<#
.SYNOPSIS
Removes an Azure DevOps inherited process.

.DESCRIPTION
Deletes an inherited process by resolving it to its type id and issuing a delete request. Processes that
are in use by a project (or system processes) cannot be deleted; the API surfaces an error in that case.
The process is removed from the 'LiveProcesses' cache on success.

.PARAMETER ProcessName
The name of the inherited process to remove.

.PARAMETER ParentProcessName
The name of the parent process (informational only).

.PARAMETER Description
The description (informational only).

.PARAMETER LookupResult
A hashtable containing the lookup result.

.PARAMETER Ensure
Specifies the desired state of the process.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function Remove-AzDoProcess
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProcessName,

        [Parameter()]
        [System.String]$ParentProcessName,

        [Parameter()]
        [System.String]$Description = '',

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoProcess] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    $process = Resolve-DevOpsProcess -ProcessName $ProcessName -OrganizationName $OrganizationName
    if ($null -eq $process)
    {
        Write-Verbose "[Remove-AzDoProcess] Process '$ProcessName' not found; nothing to remove."
        return
    }

    $params = @{
        Organization  = $OrganizationName
        ProcessTypeId = $process.id
    }

    $null = Remove-DevOpsProcess @params

    Remove-CacheItem -Key $ProcessName -Type 'LiveProcesses'
}
