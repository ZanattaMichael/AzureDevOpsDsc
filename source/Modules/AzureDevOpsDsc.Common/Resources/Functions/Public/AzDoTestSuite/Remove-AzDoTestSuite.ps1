<#
.SYNOPSIS
Removes an Azure DevOps test suite.

.DESCRIPTION
Deletes the suite. Deleting a suite in Azure DevOps deletes everything beneath it, so a suite
that still has children is left alone unless the resource sets AllowRecursiveDelete.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER PlanName
The name of the test plan the suite belongs to.

.PARAMETER Path
The suite's path under the plan's root suite.

.PARAMETER SuiteType
Passed through from the resource; not used when removing.

.PARAMETER Wiql
Passed through from the resource; not used when removing.

.PARAMETER RequirementIds
Passed through from the resource; not used when removing.

.PARAMETER AllowRecursiveDelete
Permit deletion of a suite that still contains child suites.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1 Regression' -Path 'Regression/Smoke' -AllowRecursiveDelete $true
#>
Function Remove-AzDoTestSuite
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
        [System.String]$SuiteType,

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

    Write-Verbose "[Remove-AzDoTestSuite] Started."

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = Format-AzDoTestSuitePath -Path $Path

    $plan = if ($LookupResult.planId) { @{ id = $LookupResult.planId } } else { Get-DevOpsTestPlan -Organization $organization -ProjectName $ProjectName -Name $PlanName }

    if ($null -eq $plan)
    {
        Write-Verbose "[Remove-AzDoTestSuite] Test plan '$PlanName' does not exist in project '$ProjectName'. Nothing to remove."
        return
    }

    $suite = $LookupResult.liveCache
    $suites = $null

    if ($null -eq $suite)
    {
        $suites = Get-DevOpsTestSuite -Organization $organization -ProjectName $ProjectName -TestPlanId $plan.id
        $planDetail = Get-DevOpsTestPlan -Organization $organization -ProjectName $ProjectName -Name $PlanName
        $suite = Resolve-AzDoTestSuitePath -Suites $suites -RootSuiteId $planDetail.rootSuite.id -Path $normalizedPath
    }

    if ($null -eq $suite)
    {
        Write-Verbose "[Remove-AzDoTestSuite] Suite '$normalizedPath' does not exist. Nothing to remove."
        return
    }

    if ($null -eq $suites)
    {
        $suites = Get-DevOpsTestSuite -Organization $organization -ProjectName $ProjectName -TestPlanId $plan.id
    }

    $hasChildren = @($suites | Where-Object { $_.parentSuite.id -eq $suite.id }).Count -gt 0

    if ($hasChildren -and (-not $AllowRecursiveDelete))
    {
        Write-Error "[Remove-AzDoTestSuite] Suite '$normalizedPath' in plan '$PlanName' is not empty. Deleting it would delete every suite beneath it. Set AllowRecursiveDelete = `$true to permit this."
        return
    }

    if ($hasChildren)
    {
        Write-Warning "[Remove-AzDoTestSuite] Recursively deleting suite '$normalizedPath' and all of its child suites."
    }

    Write-Verbose "[Remove-AzDoTestSuite] Removing suite '$normalizedPath'."

    return (Remove-DevOpsTestSuite -Organization $organization -ProjectName $ProjectName -TestPlanId $plan.id -TestSuiteId $suite.id)
}
