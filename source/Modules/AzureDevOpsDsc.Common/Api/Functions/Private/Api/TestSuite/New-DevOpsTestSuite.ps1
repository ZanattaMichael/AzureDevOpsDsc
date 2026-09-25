<#
.SYNOPSIS
Creates a test suite under a parent suite.

.DESCRIPTION
Creates a test suite via the Azure DevOps Test Plan API.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TestPlanId
The id of the plan the suite belongs to.

.PARAMETER ParentSuiteId
The id of the parent suite to create the new suite under.

.PARAMETER Name
The name of the suite to create.

.PARAMETER SuiteType
The kind of suite: 'StaticTestSuite', 'DynamicTestSuite' or 'RequirementTestSuite'.

.PARAMETER Wiql
The WIQL that selects the suite's test cases. Required for a DynamicTestSuite.

.PARAMETER RequirementIds
The work item ids of the requirements the suite tracks. Required for a RequirementTestSuite.

.EXAMPLE
New-DevOpsTestSuite -Organization 'myorg' -ProjectName 'MyProject' -TestPlanId 1 -ParentSuiteId 2 -Name 'Smoke' -SuiteType 'StaticTestSuite'
#>
Function New-DevOpsTestSuite
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [Int]$TestPlanId,

        [Parameter(Mandatory = $true)]
        [Int]$ParentSuiteId,

        [Parameter(Mandatory = $true)]
        [String]$Name,

        [Parameter(Mandatory = $true)]
        [String]$SuiteType,

        [Parameter()]
        [String]$Wiql,

        [Parameter()]
        [Int[]]$RequirementIds,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/Plans/{2}/suites/{3}?api-version={4}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $TestPlanId, $ParentSuiteId, $ApiVersion

    $body = @{
        suiteType = $SuiteType
        name      = $Name
    }

    if ($SuiteType -eq 'DynamicTestSuite' -and $PSBoundParameters.ContainsKey('Wiql'))
    {
        $body.queryString = $Wiql
    }

    if ($SuiteType -eq 'RequirementTestSuite' -and $RequirementIds.Count -gt 0)
    {
        $body.requirementIds = @($RequirementIds)
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        throw "[New-DevOpsTestSuite] Failed to create test suite '$Name' under parent suite id $ParentSuiteId in plan id $TestPlanId, project '$ProjectName'. Error: $_"
    }
}
