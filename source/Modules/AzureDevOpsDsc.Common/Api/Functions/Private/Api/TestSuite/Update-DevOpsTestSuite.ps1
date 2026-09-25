<#
.SYNOPSIS
Updates a test suite.

.DESCRIPTION
PATCHes a test suite via the Azure DevOps Test Plan API, addressed by id.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TestPlanId
The id of the plan the suite belongs to.

.PARAMETER TestSuiteId
The id of the suite to update.

.PARAMETER Name
A new name for the suite.

.PARAMETER Wiql
New WIQL for a DynamicTestSuite. Replaces the existing query string.

.PARAMETER RequirementIds
New requirement work item ids for a RequirementTestSuite. Replaces the existing set.

.EXAMPLE
Update-DevOpsTestSuite -Organization 'myorg' -ProjectName 'MyProject' -TestPlanId 1 -TestSuiteId 3 -Wiql "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'"
#>
Function Update-DevOpsTestSuite
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
        [Int]$TestSuiteId,

        [Parameter()]
        [String]$Name,

        [Parameter()]
        [String]$Wiql,

        [Parameter()]
        [Int[]]$RequirementIds,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/Plans/{2}/suites/{3}?api-version={4}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $TestPlanId, $TestSuiteId, $ApiVersion

    $body = @{}

    if ($PSBoundParameters.ContainsKey('Name'))           { $body.name = $Name }
    if ($PSBoundParameters.ContainsKey('Wiql'))           { $body.queryString = $Wiql }
    if ($PSBoundParameters.ContainsKey('RequirementIds')) { $body.requirementIds = @($RequirementIds) }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PATCH' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        throw "[Update-DevOpsTestSuite] Failed to update test suite id $TestSuiteId in plan id $TestPlanId, project '$ProjectName'. Error: $_"
    }
}
