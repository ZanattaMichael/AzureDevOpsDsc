<#
.SYNOPSIS
    DSC resource for managing permissions on an Azure DevOps classic Release definition.

.DESCRIPTION
    Manages the ACL on a single Release definition, using the 'ReleaseManagement' security
    namespace. The definition is resolved by name (optionally disambiguated by the folder it
    lives in) rather than by its numeric id, since the id is an implementation detail the
    configuration author does not see.

.NOTES
    Author: Michael Zanatta

    A Release definition's token uses its numeric id - '{projectId}/{definitionId}', or
    '{projectId}/{folderPath}/{definitionId}' when the definition lives in a folder other than the
    release root. The resource side resolves DefinitionName (and FolderPath, when given) to that id
    through the live 'release/definitions' search endpoint, caching the result under
    'LiveReleaseDefinitions' so New-ACLToken can resolve the same name the next time without a
    second round trip.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER DefinitionName
    The name of the Release definition.

.PARAMETER FolderPath
    The Release folder the definition lives in, for example '\Platform'. Omit when the definition
    lives at the release root, or when its name is unique across the project.

.PARAMETER isInherited
    Whether the ACL inherits permissions from its parent. Defaults to $true.

.PARAMETER Permissions
    The access control entries, as an array of hashtables:
    @{ Identity = '[ProjectName]\GroupName'; Permission = @{ ViewReleaseDefinition = 'Allow' } }

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoReleaseDefinitionPermission PlatformRelease
    {
        ProjectName    = 'Contoso'
        DefinitionName = 'Platform Release'
        FolderPath     = '\Platform'
        isInherited    = $true
        Permissions    = @(
            @{
                Identity   = '[Contoso]\Platform Team'
                Permission = @{ ViewReleaseDefinition = 'Allow'; ManageReleaseApprovers = 'Allow' }
            }
        )
    }
#>

[DscResource()]
class AzDoReleaseDefinitionPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$DefinitionName

    [DscProperty()]
    [Alias('Path')]
    [System.String]$FolderPath

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoReleaseDefinitionPermission()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoReleaseDefinitionPermission] Get()
    {
        return [AzDoReleaseDefinitionPermission]$($this.GetDscCurrentStateProperties())
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

        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName    = $CurrentResourceObject.ProjectName
        $properties.DefinitionName = $CurrentResourceObject.DefinitionName
        $properties.FolderPath     = $CurrentResourceObject.FolderPath
        $properties.isInherited    = $CurrentResourceObject.isInherited
        $properties.Permissions    = $CurrentResourceObject.Permissions
        $properties.LookupResult   = $CurrentResourceObject.LookupResult
        $properties.Ensure         = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoReleaseDefinitionPermission] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
