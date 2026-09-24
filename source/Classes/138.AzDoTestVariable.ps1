<#
.SYNOPSIS
    DSC resource for managing Azure DevOps test plan variables.

.DESCRIPTION
    Manages a named test variable and its allowed values within a project (for example
    'Browser' with the values 'Edge', 'Chrome'). Test variables are the building blocks that
    AzDoTestConfiguration combines into concrete test configurations - declare the variable
    first and make configurations depend on it.

.NOTES
    Author: Michael Zanatta

    There is no test-plan security namespace. Managing who can create or edit test variables,
    configurations, plans and suites is covered by the existing 'CSS' (area) permissions via
    AzDoAreaPermission - do not build an AzDoTestPlanPermission resource.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER Name
    The name of the test variable. Unique within the project.

.PARAMETER Description
    A description of the test variable.

.PARAMETER Values
    The allowed values for the variable, for example @('Edge', 'Chrome', 'Firefox'). Compared
    as a set - order does not matter, since the API makes no promise to preserve the order the
    values were supplied in.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoTestVariable Browser
    {
        ProjectName = 'Contoso'
        Name        = 'Browser'
        Values      = @('Edge', 'Chrome', 'Firefox')
        Ensure      = 'Present'
    }
#>

[DscResource()]
class AzDoTestVariable : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Key, Mandatory)]
    [System.String]$Name

    [DscProperty()]
    [System.String]$Description

    [DscProperty()]
    [System.String[]]$Values

    AzDoTestVariable()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoTestVariable] Get()
    {
        return [AzDoTestVariable]$($this.GetDscCurrentStateProperties())
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
        $properties.Name         = $CurrentResourceObject.Name
        $properties.Description  = $CurrentResourceObject.Description
        $properties.Values       = $CurrentResourceObject.Values
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoTestVariable] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
