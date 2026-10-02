<#
.SYNOPSIS
Updates an Azure DevOps test suite.

.DESCRIPTION
Applies the desired Wiql and/or RequirementIds to an existing suite with PATCH, addressed by
the id and plan id Get resolved. SuiteType cannot be changed once a suite exists - a Get()
'Error' status with reason 'SuiteTypeImmutable' still reaches Set(), so that refusal has to
be repeated here.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER PlanName
The name of the test plan the suite belongs to.

.PARAMETER Path
The suite's path under the plan's root suite.

.PARAMETER Wiql
The desired WIQL for a DynamicTestSuite.

.PARAMETER RequirementIds
The desired requirement work item ids for a RequirementTestSuite.

.PARAMETER AllowRecursiveDelete
Passed through from the resource; not used when updating.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1 Regression' -Path 'Regression/Active Bugs' -Wiql "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'"
#>
Function Set-AzDoTestSuite
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

    Write-Verbose "[Set-AzDoTestSuite] Started."

    if ($LookupResult.reason -eq 'SuiteTypeImmutable')
    {
        Write-Error "[Set-AzDoTestSuite] Refusing to update suite '$Path' in plan '$PlanName': SuiteType cannot be changed after creation."
        return
    }

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = Format-AzDoTestSuitePath -Path $Path

    $plan = if ($LookupResult.planId) { @{ id = $LookupResult.planId } } else { Get-DevOpsTestPlan -Organization $organization -ProjectName $ProjectName -Name $PlanName }

    if ($null -eq $plan)
    {
        Write-Error "[Set-AzDoTestSuite] Test plan '$PlanName' does not exist in project '$ProjectName'."
        return
    }

    $suite = $LookupResult.liveCache

    if ($null -eq $suite)
    {
        $suites = Get-DevOpsTestSuite -Organization $organization -ProjectName $ProjectName -TestPlanId $plan.id
        $planDetail = Get-DevOpsTestPlan -Organization $organization -ProjectName $ProjectName -Name $PlanName
        $suite = Resolve-AzDoTestSuitePath -Suites $suites -RootSuiteId $planDetail.rootSuite.id -Path $normalizedPath
    }

    if ($null -eq $suite)
    {
        Write-Error "[Set-AzDoTestSuite] Suite '$normalizedPath' does not exist in plan '$PlanName'."
        return
    }

    $params = @{
        Organization = $organization
        ProjectName  = $ProjectName
        TestPlanId   = $plan.id
        TestSuiteId  = $suite.id
    }

    if ($PSBoundParameters.ContainsKey('Wiql'))           { $params.Wiql = $Wiql }
    if ($PSBoundParameters.ContainsKey('RequirementIds')) { $params.RequirementIds = $RequirementIds }

    return (Update-DevOpsTestSuite @params)
}
