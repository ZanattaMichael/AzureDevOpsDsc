<#
.SYNOPSIS
    DSC resource for managing Azure DevOps test plans.

.DESCRIPTION
    Manages a test plan - the top-level container for test suites, configurations and runs
    within a project. See the Test Plan REST API 7.1 (`_apis/testplan/plans`).

    There is no dedicated test-plan security namespace. 'Manage test plans' and 'Manage test
    suites' are permissions on the CSS (area path) security namespace, which AzDoAreaPermission
    already manages - there is no AzDoTestPlanPermission resource.

    Creating or updating a test plan requires the DSC identity to have Basic access plus a Test
    Plans license/access level in the organization. Integration tests detect a licensing or
    access refusal up front and skip with a reason rather than failing.

.NOTES
    Author: Michael Zanatta

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER Name
    The name of the test plan.

.PARAMETER AreaPath
    The area path new test cases are assigned to by default.

.PARAMETER Iteration
    The iteration path the plan is scoped to.

.PARAMETER Owner
    The user or group who owns the plan. Resolved via Find-AzDoIdentity the same way other
    resources resolve identity strings (UPN, '[Project]\Group', or display name).

.PARAMETER StartDate
    The date testing is scheduled to start.

.PARAMETER EndDate
    The date testing is scheduled to end.

.PARAMETER State
    The plan's state: 'Active' or 'Inactive'.

.PARAMETER BuildDefinitionId
    The numeric id of the build pipeline used to identify the build under test for automated
    runs. Optional - omit for a plan with no associated build pipeline.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoTestPlan SprintOne
    {
        ProjectName = 'Contoso'
        Name        = 'Sprint 1 Regression'
        AreaPath    = 'Contoso'
        Iteration   = 'Contoso\Sprint 1'
        Owner       = 'user@domain.com'
        State       = 'Active'
        Ensure      = 'Present'
    }
#>

[DscResource()]
class AzDoTestPlan : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Key, Mandatory)]
    [System.String]$Name

    [DscProperty()]
    [System.String]$AreaPath

    [DscProperty()]
    [System.String]$Iteration

    [DscProperty()]
    [System.String]$Owner

    [DscProperty()]
    [System.String]$StartDate

    [DscProperty()]
    [System.String]$EndDate

    [DscProperty()]
    [ValidateSet('Active', 'Inactive')]
    [System.String]$State

    [DscProperty()]
    [System.Int32]$BuildDefinitionId

    AzDoTestPlan()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoTestPlan] Get()
    {
        return [AzDoTestPlan]$($this.GetDscCurrentStateProperties())
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

        $properties.ProjectName       = $CurrentResourceObject.ProjectName
        $properties.Name              = $CurrentResourceObject.Name
        $properties.AreaPath          = $CurrentResourceObject.AreaPath
        $properties.Iteration         = $CurrentResourceObject.Iteration
        $properties.Owner             = $CurrentResourceObject.Owner
        $properties.StartDate         = $CurrentResourceObject.StartDate
        $properties.EndDate           = $CurrentResourceObject.EndDate
        $properties.State             = $CurrentResourceObject.State
        $properties.BuildDefinitionId = $CurrentResourceObject.BuildDefinitionId
        $properties.LookupResult      = $CurrentResourceObject.LookupResult
        $properties.Ensure            = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoTestPlan] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
