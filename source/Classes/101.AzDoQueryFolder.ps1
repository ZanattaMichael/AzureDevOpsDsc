<#
.SYNOPSIS
    DSC resource for managing Azure DevOps work item query folders.

.DESCRIPTION
    Manages a folder within a project's shared query tree. Query folders are configuration in
    their own right: they carry ACLs, and a query cannot be created at a path whose folders do
    not exist.

    Declare a folder with this resource and make queries beneath it depend on it, rather than
    letting each query create its own ancestry - two queries in the same folder would otherwise
    race to create it, and Test() results would depend on apply order.

.NOTES
    Author: Michael Zanatta

    Only the 'Shared Queries' tree is manageable. 'My Queries' is per-user and has no meaningful
    desired state for a machine-level configuration.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER Path
    The full path of the folder, including the root, for example 'Shared Queries/Platform/Release'.
    Backslashes are accepted and normalized to forward slashes.

.PARAMETER AllowRecursiveDelete
    Deleting a folder deletes everything beneath it. Removal of a folder that still has children
    is refused unless this is set to $true.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoQueryFolder Platform
    {
        ProjectName = 'Contoso'
        Path        = 'Shared Queries/Platform'
        Ensure      = 'Present'
    }
#>

[DscResource()]
class AzDoQueryFolder : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty(Key, Mandatory)]
    [Alias('FolderPath')]
    [System.String]$Path

    [DscProperty()]
    [System.Boolean]$AllowRecursiveDelete = $false

    AzDoQueryFolder()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoQueryFolder] Get()
    {
        return [AzDoQueryFolder]$($this.GetDscCurrentStateProperties())
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

        $properties.ProjectName          = $CurrentResourceObject.ProjectName
        $properties.Path                 = $CurrentResourceObject.Path
        $properties.AllowRecursiveDelete = $CurrentResourceObject.AllowRecursiveDelete
        $properties.LookupResult         = $CurrentResourceObject.LookupResult
        $properties.Ensure               = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoQueryFolder] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
