<#
.SYNOPSIS
Deletes a test suite.

.DESCRIPTION
Deletes a test suite via the Azure DevOps Test Plan API, addressed by id. Deleting a suite
deletes every suite beneath it.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TestPlanId
The id of the plan the suite belongs to.

.PARAMETER TestSuiteId
The id of the suite to delete.

.EXAMPLE
Remove-DevOpsTestSuite -Organization 'myorg' -ProjectName 'MyProject' -TestPlanId 1 -TestSuiteId 3
#>
Function Remove-DevOpsTestSuite
{
    [CmdletBinding()]
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
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/Plans/{2}/suites/{3}?api-version={4}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $TestPlanId, $TestSuiteId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        throw "[Remove-DevOpsTestSuite] Failed to delete test suite id $TestSuiteId in plan id $TestPlanId, project '$ProjectName'. Error: $_"
    }
}
