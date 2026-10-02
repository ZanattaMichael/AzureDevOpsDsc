<#
.SYNOPSIS
Deletes a test plan variable.

.DESCRIPTION
Deletes a test variable via the Azure DevOps Test Plan API, addressed by id.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TestVariableId
The id of the variable to delete.

.EXAMPLE
Remove-DevOpsTestVariable -Organization 'myorg' -ProjectName 'MyProject' -TestVariableId 1
#>
Function Remove-DevOpsTestVariable
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [Int]$TestVariableId,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/variables/{2}?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $TestVariableId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        throw "[Remove-DevOpsTestVariable] Failed to delete test variable id $TestVariableId in project '$ProjectName'. Error: $_"
    }
}
