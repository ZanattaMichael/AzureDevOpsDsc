<#
.SYNOPSIS
    DSC resource for managing Azure DevOps pipeline variable groups.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
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

    AzDoVariableGroup()
    {
        $this.Construct()
    }

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
        $properties.LookupResult      = $CurrentResourceObject.LookupResult
        $properties.Ensure            = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoVariableGroup] Current state properties: $($properties | Out-String)"

        return $properties
    }
}