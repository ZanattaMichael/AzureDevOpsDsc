<#
.SYNOPSIS
Deletes a test configuration.

.DESCRIPTION
Deletes a test configuration via the Azure DevOps Test Plan API, addressed by id.

The id goes in the 'testConfiguartionId' query parameter (the spelling is the API's own), not
the path: the route answers 405 when the id is a path segment.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TestConfigurationId
The id of the configuration to delete.

.EXAMPLE
Remove-DevOpsTestConfiguration -Organization 'myorg' -ProjectName 'MyProject' -TestConfigurationId 1
#>
Function Remove-DevOpsTestConfiguration
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [Int]$TestConfigurationId,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/configurations?testConfiguartionId={2}&api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $TestConfigurationId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        throw "[Remove-DevOpsTestConfiguration] Failed to delete test configuration id $TestConfigurationId in project '$ProjectName'. Error: $_"
    }
}
