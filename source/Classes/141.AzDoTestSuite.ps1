<#
.SYNOPSIS
    DSC resource for managing Azure DevOps test suites.

.DESCRIPTION
    Manages a test suite beneath a test plan's root suite. Suites are identified by their path
    of suite names under the root, for example 'Regression/Smoke' - the same way AzDoQueryFolder
    treats query folder paths. Declare an ancestor suite as its own AzDoTestSuite resource and
    make descendant suites depend on it, rather than letting each suite create its own ancestry.

    There is no dedicated test-plan security namespace. 'Manage test plans' and 'Manage test
    suites' are permissions on the CSS (area path) security namespace, which AzDoAreaPermission
    already manages - there is no AzDoTestSuitePermission resource.

.NOTES
    Author: Michael Zanatta

    A StaticTestSuite has no query - it holds test cases added directly. A DynamicTestSuite's
    membership is computed from Wiql, which the Test Plan API re-normalizes on return the same
    way the work item Queries API does; Test() compares it with ConvertTo-NormalizedWiql and
    always writes back exactly the WIQL the configuration supplied. A RequirementTestSuite
    tracks a fixed set of requirement work items via RequirementIds.

    Deleting a suite deletes every suite beneath it. Removal of a suite that still has children
    is refused unless AllowRecursiveDelete is set to $true.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER PlanName
    The name of the test plan the suite belongs to.

.PARAMETER Path
    The suite's path under the plan's root suite, for example 'Regression/Smoke'. Backslashes
    are accepted and normalized to forward slashes.

.PARAMETER SuiteType
    The kind of suite: 'StaticTestSuite', 'DynamicTestSuite' or 'RequirementTestSuite'.

.PARAMETER Wiql
    The WIQL that selects the suite's test cases. Only meaningful for a DynamicTestSuite.

.PARAMETER RequirementIds
    The work item ids of the requirements the suite tracks. Only meaningful for a
    RequirementTestSuite.

.PARAMETER AllowRecursiveDelete
    Deleting a suite deletes everything beneath it. Removal of a suite that still has children
    is refused unless this is set to $true.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoTestSuite Smoke
    {
        ProjectName = 'Contoso'
        PlanName    = 'Sprint 1 Regression'
        Path        = 'Regression/Smoke'
        SuiteType   = 'StaticTestSuite'
        Ensure      = 'Present'
    }

.EXAMPLE
    AzDoTestSuite ActiveBugs
    {
        ProjectName = 'Contoso'
        PlanName    = 'Sprint 1 Regression'
        Path        = 'Regression/Active Bugs'
        SuiteType   = 'DynamicTestSuite'
        Wiql        = "SELECT [System.Id] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.State] = 'Active'"
        Ensure      = 'Present'
    }
#>

[DscResource()]
class AzDoTestSuite : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$PlanName

    [DscProperty(Key, Mandatory)]
    [System.String]$Path

    [DscProperty()]
    [ValidateSet('StaticTestSuite', 'DynamicTestSuite', 'RequirementTestSuite')]
    [System.String]$SuiteType = 'StaticTestSuite'

    [DscProperty()]
    [System.String]$Wiql

    [DscProperty()]
    [System.Int32[]]$RequirementIds

    [DscProperty()]
    [System.Boolean]$AllowRecursiveDelete = $false

    AzDoTestSuite()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoTestSuite] Get()
    {
        return [AzDoTestSuite]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @('SuiteType')
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
        $properties.PlanName             = $CurrentResourceObject.PlanName
        $properties.Path                 = $CurrentResourceObject.Path
        $properties.SuiteType            = $CurrentResourceObject.SuiteType
        $properties.Wiql                 = $CurrentResourceObject.Wiql
        $properties.RequirementIds       = $CurrentResourceObject.RequirementIds
        $properties.AllowRecursiveDelete = $CurrentResourceObject.AllowRecursiveDelete
        $properties.LookupResult         = $CurrentResourceObject.LookupResult
        $properties.Ensure               = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoTestSuite] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
