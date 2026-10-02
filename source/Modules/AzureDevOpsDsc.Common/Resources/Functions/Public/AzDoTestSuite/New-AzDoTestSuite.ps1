<#
.SYNOPSIS
Creates an Azure DevOps test suite.

.DESCRIPTION
Creates the suite beneath its parent. The parent must already exist - either an ancestor
suite at a shorter path, or the plan's root suite when Path has a single segment. This
function does not create ancestry, because doing so would let two suite resources in the
same configuration race to create a shared parent. Declare each level as its own
AzDoTestSuite resource and chain them with DependsOn.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER PlanName
The name of the test plan the suite belongs to.

.PARAMETER Path
The suite's path under the plan's root suite.

.PARAMETER SuiteType
The kind of suite to create.

.PARAMETER Wiql
The WIQL for a DynamicTestSuite.

.PARAMETER RequirementIds
The requirement work item ids for a RequirementTestSuite.

.PARAMETER AllowRecursiveDelete
Passed through from the resource; not used when creating.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1 Regression' -Path 'Regression/Smoke' -SuiteType 'StaticTestSuite'
#>
Function New-AzDoTestSuite
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$PlanName,

        [Parameter(Mandatory = $true)]
        [System.String]$Path,

        [Parameter()]
        [System.String]$SuiteType = 'StaticTestSuite',

        [Parameter()]
        [System.String]$Wiql,

        [Parameter()]
        [System.Int32[]]$RequirementIds,

        [Parameter()]
        [System.Boolean]$AllowRecursiveDelete,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoTestSuite] Started."

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = Format-AzDoTestSuitePath -Path $Path
    $segments       = @($normalizedPath -split '/' | Where-Object { -not [String]::IsNullOrWhiteSpace($_) })

    if ($segments.Count -eq 0)
    {
        Write-Error "[New-AzDoTestSuite] '$normalizedPath' is not a valid suite path."
        return
    }

    $plan = Get-DevOpsTestPlan -Organization $organization -ProjectName $ProjectName -Name $PlanName

    if ($null -eq $plan)
    {
        Write-Error "[New-AzDoTestSuite] Test plan '$PlanName' does not exist in project '$ProjectName'."
        return
    }

    $suiteName = $segments[-1]
    $parentSegments = if ($segments.Count -gt 1) { $segments[0..($segments.Count - 2)] } else { @() }
    $parentPath = $parentSegments -join '/'

    $suites = Get-DevOpsTestSuite -Organization $organization -ProjectName $ProjectName -TestPlanId $plan.id
    $parentSuiteId = if ($parentSegments.Count -eq 0)
    {
        $plan.rootSuite.id
    }
    else
    {
        $parent = Resolve-AzDoTestSuitePath -Suites $suites -RootSuiteId $plan.rootSuite.id -Path $parentPath

        if ($null -eq $parent)
        {
            Write-Error "[New-AzDoTestSuite] Parent suite '$parentPath' does not exist in plan '$PlanName'. Create it first (AzDoTestSuite with DependsOn)."
            return
        }

        $parent.id
    }

    Write-Verbose "[New-AzDoTestSuite] Creating suite '$suiteName' under parent suite id $parentSuiteId in plan '$PlanName'."

    $params = @{
        Organization  = $organization
        ProjectName   = $ProjectName
        TestPlanId    = $plan.id
        ParentSuiteId = $parentSuiteId
        Name          = $suiteName
        SuiteType     = $SuiteType
    }

    if ($SuiteType -eq 'DynamicTestSuite' -and $PSBoundParameters.ContainsKey('Wiql'))
    {
        $params.Wiql = $Wiql
    }

    if ($SuiteType -eq 'RequirementTestSuite' -and $RequirementIds.Count -gt 0)
    {
        $params.RequirementIds = $RequirementIds
    }

    return (New-DevOpsTestSuite @params)
}
