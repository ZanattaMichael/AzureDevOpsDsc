<#
.SYNOPSIS
Resolves an Azure DevOps process by name from cache, falling back to a live lookup.

.DESCRIPTION
Looks up a process in the 'LiveProcesses' cache by name. If it is not cached (e.g. created after the
last cache initialization), it falls back to a live 'List-DevOpsProcess' query and matches by name. The
returned object exposes an 'id' property (the process type id GUID) used to build REST routes and ACL
tokens, matching the shape stored by the cache initializer.

.PARAMETER ProcessName
The name of the process to resolve.

.PARAMETER OrganizationName
The name of the Azure DevOps organization.

.OUTPUTS
The resolved process object, or $null when no process with that name exists.

.EXAMPLE
Resolve-DevOpsProcess -ProcessName 'Agile' -OrganizationName 'myorg'
#>
function Resolve-DevOpsProcess
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$ProcessName,

        [Parameter(Mandatory = $true)]
        [string]$OrganizationName
    )

    $process = Get-CacheItem -Key $ProcessName -Type 'LiveProcesses'
    if ($null -ne $process)
    {
        return $process
    }

    Write-Verbose "[Resolve-DevOpsProcess] Process '$ProcessName' not in cache — falling back to live API lookup."
    $process = List-DevOpsProcess -Organization $OrganizationName |
        Where-Object { $_.name -eq $ProcessName } | Select-Object -First 1

    if ($null -ne $process)
    {
        Add-CacheItem -Key $process.name -Value $process -Type 'LiveProcesses' -SuppressWarning
    }

    return $process
}
