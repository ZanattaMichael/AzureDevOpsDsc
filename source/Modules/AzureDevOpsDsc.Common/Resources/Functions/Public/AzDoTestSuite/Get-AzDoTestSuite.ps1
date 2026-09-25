<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps test suite.

.DESCRIPTION
Resolves PlanName to a plan, then walks the plan's flat suite list from its root suite to
find the suite at Path (see Resolve-AzDoTestSuitePath) - the Test Plan API has no
get-suite-by-path endpoint. Wiql is compared with ConvertTo-NormalizedWiql, since the API
re-normalizes a dynamic suite's query string the same way it re-normalizes a saved query's;
what gets written back is always the WIQL the configuration supplied.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER PlanName
The name of the test plan the suite belongs to.

.PARAMETER Path
The suite's path under the plan's root suite.

.PARAMETER SuiteType
The desired kind of suite. Immutable once created - a mismatch is reported as an error rather
than drift, since there is no way for Set() to change it.

.PARAMETER Wiql
The desired WIQL for a DynamicTestSuite.

.PARAMETER RequirementIds
The desired requirement work item ids for a RequirementTestSuite.

.PARAMETER AllowRecursiveDelete
Passed through from the resource; not used by the lookup.

.PARAMETER LookupResult
The lookup result from a previous call, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1 Regression' -Path 'Regression/Smoke'
#>
Function Get-AzDoTestSuite
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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

    Write-Verbose "[Get-AzDoTestSuite] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
        path              = (Format-AzDoTestSuitePath -Path $Path)
    }

    $normalizedPath = $result.path

    if ([String]::IsNullOrWhiteSpace($normalizedPath))
    {
        Write-Error "[Get-AzDoTestSuite] A test suite path must be supplied."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'EmptyPath'
        return $result
    }

    $organization = Get-AzDoOrganizationName
    $plan = Get-DevOpsTestPlan -Organization $organization -ProjectName $ProjectName -Name $PlanName

    if ($null -eq $plan)
    {
        Write-Error "[Get-AzDoTestSuite] Test plan '$PlanName' does not exist in project '$ProjectName'."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'PlanNotFound'
        return $result
    }

    $result.planId = $plan.id

    $suites = Get-DevOpsTestSuite -Organization $organization -ProjectName $ProjectName -TestPlanId $plan.id
    $suite = Resolve-AzDoTestSuitePath -Suites $suites -RootSuiteId $plan.rootSuite.id -Path $normalizedPath

    if ($null -eq $suite)
    {
        Write-Verbose "[Get-AzDoTestSuite] Suite '$normalizedPath' does not exist in plan '$PlanName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.liveCache = $suite
    $result.Ensure    = [Ensure]::Present

    # SuiteType cannot be changed once a suite exists. A mismatch is a refusal, not drift for
    # Set() to fix - the Get()-Error-still-runs-Set() rule means Set() must repeat this check.
    if ($PSBoundParameters.ContainsKey('SuiteType') -and (-not [String]::IsNullOrWhiteSpace($SuiteType)))
    {
        if ($SuiteType -ne [String]$suite.suiteType)
        {
            Write-Error "[Get-AzDoTestSuite] Suite '$normalizedPath' in plan '$PlanName' is a '$($suite.suiteType)', not a '$SuiteType'. SuiteType cannot be changed after creation - remove and recreate the suite."
            $result.status = [DSCGetSummaryState]::Error
            $result.reason = 'SuiteTypeImmutable'
            return $result
        }
    }

    $propertiesChanged = @()

    if ($PSBoundParameters.ContainsKey('Wiql') -and (-not [String]::IsNullOrWhiteSpace($Wiql)))
    {
        $desiredWiql = ConvertTo-NormalizedWiql -Wiql $Wiql
        $currentWiql = ConvertTo-NormalizedWiql -Wiql ([String]$suite.queryString)

        if ($desiredWiql -ne $currentWiql)
        {
            Write-Verbose "[Get-AzDoTestSuite] Wiql differs for '$normalizedPath'."
            $propertiesChanged += 'Wiql'
        }
    }

    if ($PSBoundParameters.ContainsKey('RequirementIds') -and $RequirementIds.Count -gt 0)
    {
        $desiredSet = @($RequirementIds | Sort-Object -Unique)
        $currentSet = @($suite.requirementIds | Sort-Object -Unique)

        if (($desiredSet -join ',') -ne ($currentSet -join ','))
        {
            Write-Verbose "[Get-AzDoTestSuite] RequirementIds differ for '$normalizedPath'."
            $propertiesChanged += 'RequirementIds'
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoTestSuite] Test suite '$normalizedPath' status: $($result.status)."

    return $result
}
