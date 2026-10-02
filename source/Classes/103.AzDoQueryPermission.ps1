<#
.SYNOPSIS
    DSC resource for managing permissions on Azure DevOps work item query folders.

.DESCRIPTION
    Manages the ACL for a folder in a project's shared query tree, using the
    'WorkItemQueryFolders' security namespace.

    Permissions are administered on folders and inherited by the queries beneath them, which is
    how query security is normally organised in practice. Omitting QueryPath targets the
    project's query root, so a single declaration can set the baseline for every query in the
    project.

.NOTES
    Author: Michael Zanatta

    The ACL token addresses folders by GUID, not by name: '$/{projectId}/{folderId}/{subfolderId}'.
    The resource resolves the readable path to that chain of ids before building the token, so a
    folder that has been renamed in the UI still resolves as long as the configured path matches.

    Like the other hierarchical-namespace permission resources (AzDoAreaPermission,
    AzDoIterationPermission, AzDoPipelinePermission), evaluating this resource can be slow when
    the ACL fetch cannot be scoped and falls back to reading the namespace in full.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER QueryPath
    The full path of the query folder, including the root - for example
    'Shared Queries/Platform'. Omit to target the project's query root, which is the parent of
    every query in the project.

.PARAMETER isInherited
    Whether the ACL inherits permissions from its parent. Defaults to $true.

.PARAMETER Permissions
    The access control entries, as an array of hashtables:
    @{ Identity = '[ProjectName]\GroupName'; Permission = @{ Read = 'Allow'; Contribute = 'Deny' } }

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoQueryPermission PlatformQueries
    {
        ProjectName = 'Contoso'
        QueryPath   = 'Shared Queries/Platform'
        isInherited = $true
        Permissions = @(
            @{
                Identity    = '[Contoso]\Platform Team'
                Permission  = @{ Read = 'Allow'; Contribute = 'Allow' }
            }
        )
    }
#>

[DscResource()]
class AzDoQueryPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty()]
    [Alias('Path')]
    [System.String]$QueryPath

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoQueryPermission()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoQueryPermission] Get()
    {
        return [AzDoQueryPermission]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName  = $CurrentResourceObject.ProjectName
        $properties.QueryPath    = $CurrentResourceObject.QueryPath
        $properties.isInherited  = $CurrentResourceObject.isInherited
        $properties.Permissions  = $CurrentResourceObject.Permissions
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoQueryPermission] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
