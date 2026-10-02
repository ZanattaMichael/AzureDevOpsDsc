<#
.SYNOPSIS
    DSC resource for managing permissions on Azure DevOps pipeline (build) folders.

.DESCRIPTION
    Manages the ACL on a pipeline folder, using the 'Build' security namespace. Definitions beneath
    the folder inherit from it, which is how pipeline permissions are normally administered.

.NOTES
    Author: Michael Zanatta

    A pipeline folder's token addresses the folder by path - '{projectId}/{folderPath}' - whereas a
    definition's token uses its numeric id. Until this resource was added, the Build branch of the
    ACL layer only understood the definition form, so folder-level pipeline permissions could not
    be expressed at all - including through AzDoPipelinePermission, which is now able to target a
    folder as well.

    Omitting FolderPath targets the project's build root.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER FolderPath
    The full path of the pipeline folder, for example '\Platform'. Omit to target the project's
    build root.

.PARAMETER isInherited
    Whether the ACL inherits permissions from its parent. Defaults to $true.

.PARAMETER Permissions
    The access control entries, as an array of hashtables:
    @{ Identity = '[ProjectName]\GroupName'; Permission = @{ ViewBuilds = 'Allow' } }

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoPipelineFolderPermission PlatformPipelines
    {
        ProjectName = 'Contoso'
        FolderPath  = '\Platform'
        isInherited = $true
        Permissions = @(
            @{
                Identity   = '[Contoso]\Platform Team'
                Permission = @{ ViewBuilds = 'Allow'; QueueBuilds = 'Allow' }
            }
        )
    }
#>

[DscResource()]
class AzDoPipelineFolderPermission : AzDevOpsDscResourceBase
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

    AzDoPipelineFolderPermission()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoPipelineFolderPermission] Get()
    {
        return [AzDoPipelineFolderPermission]$($this.GetDscCurrentStateProperties())
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

        Write-Verbose "[AzDoPipelineFolderPermission] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
