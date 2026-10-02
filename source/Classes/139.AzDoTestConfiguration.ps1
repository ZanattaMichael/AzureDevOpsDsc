<#
.SYNOPSIS
    DSC resource for managing Azure DevOps test configurations.

.DESCRIPTION
    Manages a named test configuration built from one or more test variable/value pairs (for
    example 'Windows 11 + Edge'). Every pair must reference a test variable that already exists
    in the project, and a value that variable allows - AzDoTestConfiguration validates both and
    fails with a clear message when either is missing, rather than letting the API's generic
    error stand in for it.

.NOTES
    Author: Michael Zanatta

    There is no test-plan security namespace. Managing who can create or edit test
    configurations is covered by the existing 'CSS' (area) permissions via AzDoAreaPermission -
    do not build an AzDoTestPlanPermission resource.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER Name
    The name of the test configuration. Unique within the project.

.PARAMETER Description
    A description of the configuration.

.PARAMETER IsDefault
    Whether new test plans/suites should use this configuration by default.

.PARAMETER State
    'active' or 'inactive'. Defaults to 'active'.

.PARAMETER Values
    The variable/value pairs that make up the configuration, each written as
    'VariableName=Value' (for example 'Browser=Edge', 'OS=Windows 11'). Each VariableName must
    be an existing AzDoTestVariable in the project, and each Value must be one of that
    variable's allowed values.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoTestConfiguration Windows11Edge
    {
        ProjectName = 'Contoso'
        Name        = 'Windows 11 + Edge'
        Values      = @('Browser=Edge', 'OS=Windows 11')
        Ensure      = 'Present'
        DependsOn   = '[AzDoTestVariable]Browser', '[AzDoTestVariable]OS'
    }
#>

[DscResource()]
class AzDoTestConfiguration : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Key, Mandatory)]
    [System.String]$Name

    [DscProperty()]
    [System.String]$Description

    [DscProperty()]
    [System.Boolean]$IsDefault = $false

    [DscProperty()]
    [ValidateSet('active', 'inactive')]
    [System.String]$State = 'active'

    [DscProperty()]
    [System.String[]]$Values

    AzDoTestConfiguration()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoTestConfiguration] Get()
    {
        return [AzDoTestConfiguration]$($this.GetDscCurrentStateProperties())
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
        $properties.IsDefault    = $CurrentResourceObject.IsDefault
        $properties.State        = $CurrentResourceObject.State
        $properties.Values       = $CurrentResourceObject.Values
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoTestConfiguration] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
