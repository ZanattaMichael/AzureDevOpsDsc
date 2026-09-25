<#
.SYNOPSIS
Deletes a test plan.

.DESCRIPTION
Deletes a test plan via the Azure DevOps Test Plan API, addressed by id.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TestPlanId
The id of the plan to delete.

.EXAMPLE
Remove-DevOpsTestPlan -Organization 'myorg' -ProjectName 'MyProject' -TestPlanId 1
#>
Function Remove-DevOpsTestPlan
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

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/plans/{2}?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $TestPlanId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        throw "[Remove-DevOpsTestPlan] Failed to delete test plan id $TestPlanId in project '$ProjectName'. Error: $_"
    }
}
