<#
.SYNOPSIS
    DSC resource for managing permissions on Azure DevOps classic Release folders.

.DESCRIPTION
    Manages the ACL on a Release folder, using the 'ReleaseManagement' security namespace.
    Release definitions beneath the folder inherit from it, which is how release permissions are
    normally administered.

.NOTES
    Author: Michael Zanatta

    A Release folder's token addresses the folder by path - '{projectId}/{folderPath}' - whereas a
    release definition's token uses its numeric id, with the root folder omitted rather than
    written out.

    Omitting FolderPath targets the project's release root.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER FolderPath
    The full path of the Release folder, for example '\Platform'. Omit to target the project's
    release root.

.PARAMETER isInherited
    Whether the ACL inherits permissions from its parent. Defaults to $true.

.PARAMETER Permissions
    The access control entries, as an array of hashtables:
    @{ Identity = '[ProjectName]\GroupName'; Permission = @{ ViewReleases = 'Allow' } }

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoReleaseFolderPermission PlatformReleases
    {
        ProjectName = 'Contoso'
        FolderPath  = '\Platform'
        isInherited = $true
        Permissions = @(
            @{
                Identity   = '[Contoso]\Platform Team'
                Permission = @{ ViewReleases = 'Allow'; ManageReleases = 'Allow' }
            }
        )
    }
#>

[DscResource()]
class AzDoReleaseFolderPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty()]
    [Alias('Path')]
    [System.String]$FolderPath

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoReleaseFolderPermission()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoReleaseFolderPermission] Get()
    {
        return [AzDoReleaseFolderPermission]$($this.GetDscCurrentStateProperties())
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
        $properties.FolderPath   = $CurrentResourceObject.FolderPath
        $properties.isInherited  = $CurrentResourceObject.isInherited
        $properties.Permissions  = $CurrentResourceObject.Permissions
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoReleaseFolderPermission] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
