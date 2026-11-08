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
    The variables of the group, keyed by variable name. Each entry is either a plain string value
    (a non-secret variable) or a hashtable with 'value' and 'isSecret' (key names are not case
    sensitive):

        Variables = @{
            APP_ENV      = 'production'
            APP_API_KEY  = @{ value = 'p@ssw0rd'; isSecret = $true }
        }

    A secret variable is stored encrypted by Azure DevOps and can never be read back, so Test only
    checks that it exists and is secret - a changed secret value is not detected as drift. Its value
    is written when the configuration supplies one; '@{ isSecret = $true }' with no value keeps the
    value already stored. When Variables is specified it is the complete set: a variable that is
    not listed is removed on Set. When it is not specified the live variables are left alone.

.PARAMETER AllowAccess
    Whether all pipelines can access this variable group. Defaults to $false.

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
        $properties.LookupResult      = $CurrentResourceObject.LookupResult
        $properties.Ensure            = $CurrentResourceObject.Ensure

        # Variables may hold secrets: log property names only, never the values.
        Write-Verbose "[AzDoVariableGroup] Current state properties:`n$($this.FormatPropertiesForLog($properties))"

        return $properties
    }
}
