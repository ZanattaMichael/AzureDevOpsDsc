<#
.SYNOPSIS
    DSC resource for managing Azure DevOps pipeline variable groups.
.DESCRIPTION
    This resource manages variable groups in Azure DevOps, allowing shared variables and secrets to
    be used across multiple pipelines within a project.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER VariableGroupName
    The name of the variable group. This is a key property.

.PARAMETER Description
    An optional description for the variable group.

.PARAMETER VariableGroupType
    The type of variable group. Valid values are Vsts (standard) and AzureKeyVault. Defaults to Vsts.

.PARAMETER Variables
    A hashtable of key-value pairs representing the variables.

.PARAMETER AllowAccess
    Whether all pipelines can access this variable group. Defaults to $false.

.PARAMETER SharedWithProjects
    Additional projects, beyond ProjectName, that the variable group is also shared with. Compared
    only when the configuration states it, so a variable group shared by hand outside this
    resource is left alone. Add and remove drift against the live
    'variableGroupProjectReferences' is detected and corrected by Set.
    Known limitation: Azure DevOps Services currently refuses the share call with
    "Sharing of variable group is not allowed.", in which case Set throws that error.

.PARAMETER SharedNameOverrides
    Optional hashtable of ProjectName -> the name the variable group is shown under in that
    project, e.g. @{ Fabrikam = 'shared-settings' }. Only consulted for projects named in
    SharedWithProjects; the owning project's reference always uses VariableGroupName.

#>

[DscResource()]
class AzDoVariableGroup : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$VariableGroupName

    [DscProperty()]
    [System.String]$Description

    [DscProperty()]
    [ValidateSet('Vsts', 'AzureKeyVault')]
    [System.String]$VariableGroupType = 'Vsts'

    [DscProperty()]
    [HashTable]$Variables

    [DscProperty()]
    [System.Boolean]$AllowAccess = $false

    [DscProperty()]
    [System.String[]]$SharedWithProjects

    [DscProperty()]
    [HashTable]$SharedNameOverrides

    AzDoVariableGroup()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoVariableGroup] Get()
    {
        return [AzDoVariableGroup]$($this.GetDscCurrentStateProperties())
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

        $properties.ProjectName       = $CurrentResourceObject.ProjectName
        $properties.VariableGroupName = $CurrentResourceObject.VariableGroupName
        $properties.Description       = $CurrentResourceObject.Description
        $properties.VariableGroupType = $CurrentResourceObject.VariableGroupType
        $properties.Variables         = $CurrentResourceObject.Variables
        $properties.AllowAccess       = $CurrentResourceObject.AllowAccess
        $properties.SharedWithProjects  = $CurrentResourceObject.SharedWithProjects
        $properties.SharedNameOverrides = $CurrentResourceObject.SharedNameOverrides
        $properties.LookupResult      = $CurrentResourceObject.LookupResult
        $properties.Ensure            = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoVariableGroup] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
