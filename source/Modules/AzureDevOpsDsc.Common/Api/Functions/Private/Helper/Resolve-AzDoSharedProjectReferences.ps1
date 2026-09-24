<#
.SYNOPSIS
Builds the project reference array used to share a variable group or service connection with
additional projects.

.DESCRIPTION
Variable groups and service connections both model cross-project sharing the same way: an array
of project references, each carrying the id/name of a project the object is visible in plus the
name (and description) it is shown under there. This resolves the owning project plus every
project in SharedWithProjects to that shape, ready to send as 'variableGroupProjectReferences' or
'serviceEndpointProjectReferences'.

The owning project's reference always uses DefaultName - only the additional (shared) projects
can be given a different display name via SharedNameOverrides, matching how the Azure DevOps UI
itself treats the owning project's reference as the object's real name.

Throws when a named project cannot be resolved, so a typo in SharedWithProjects fails loudly
instead of silently sharing with nothing. Callers should wrap the call in a try/catch and convert
the exception into a normal Write-Error, matching every other resource function in this module.

.PARAMETER ProjectName
The owning project's name.

.PARAMETER SharedWithProjects
Additional project names the object should be shared with, beyond ProjectName.

.PARAMETER SharedNameOverrides
Optional hashtable of ProjectName -> the reference name to use in that project. Only consulted for
projects other than the owning ProjectName.

.PARAMETER DefaultName
The reference name used for the owning project, and for any shared project with no entry in
SharedNameOverrides.

.PARAMETER Description
The description carried on every project reference.

.OUTPUTS
Object[]. Returns naturally - PowerShell unrolls a single-element array on return (see CLAUDE.md),
so wrap the call in @() at the call site to guarantee an array even when the object is not shared
with anyone else.

.EXAMPLE
$refs = @(Resolve-AzDoSharedProjectReferences -ProjectName 'Contoso' -SharedWithProjects @('Fabrikam') -DefaultName 'common-settings')
#>
function Resolve-AzDoSharedProjectReferences
{
    [CmdletBinding()]
    [OutputType([Object[]])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]$ProjectName,

        [Parameter()]
        [System.String[]]$SharedWithProjects,

        [Parameter()]
        [HashTable]$SharedNameOverrides,

        [Parameter(Mandatory = $true)]
        [System.String]$DefaultName,

        [Parameter()]
        [System.String]$Description
    )

    $sharedNames     = @($SharedWithProjects | Where-Object { $_ -and $_ -ne $ProjectName } | Select-Object -Unique)
    $allProjectNames = @($ProjectName) + $sharedNames

    $references = [System.Collections.Generic.List[Object]]::new()

    foreach ($name in $allProjectNames)
    {
        $project = Resolve-AzDoProject -ProjectName $name
        if (-not $project)
        {
            throw "[Resolve-AzDoSharedProjectReferences] Project '$name' was not found; cannot share with it."
        }

        $refName = if ($name -ne $ProjectName -and $SharedNameOverrides -and $SharedNameOverrides.ContainsKey($name))
        {
            $SharedNameOverrides[$name]
        }
        else
        {
            $DefaultName
        }

        $references.Add(
            @{
                projectReference = @{ id = $project.id; name = $project.name }
                name             = $refName
                description      = $Description
            }
        )
    }

    return $references.ToArray()
}
