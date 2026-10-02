<#
.SYNOPSIS
Retrieves test suites for a plan.

.DESCRIPTION
Calls the Azure DevOps Test Plan API's suites endpoint for a plan. The API has no
get-by-path lookup, so this lists every suite in the plan (flat, each carrying
.parentSuite.id) and Resolve-AzDoTestSuitePath walks it to find a suite by path.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TestPlanId
The id of the plan the suites belong to.

.EXAMPLE
Get-DevOpsTestSuite -Organization 'myorg' -ProjectName 'MyProject' -TestPlanId 1
#>
Function Get-DevOpsTestSuite
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [Int]$TestPlanId,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/Plans/{2}/suites?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $TestPlanId, $ApiVersion

    try
    {
        $response = Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET'
    }
    catch
    {
        throw "[Get-DevOpsTestSuite] Failed to list suites for test plan id $TestPlanId in project '$ProjectName'. Error: $_"
    }

    return @($response.value)
}
