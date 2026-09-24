<#
.SYNOPSIS
Updates a test configuration.

.DESCRIPTION
PATCHes a test configuration via the Azure DevOps Test Plan API, addressed by id. The API
requires 'name' on every PATCH even when the name itself is not changing.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TestConfigurationId
The id of the configuration to update.

.PARAMETER Name
The configuration's name.

.PARAMETER Description
A new description.

.PARAMETER IsDefault
Whether new test plans/suites should use this configuration by default.

.PARAMETER State
'active' or 'inactive'.

.PARAMETER Values
New variable/value pairs. Replaces the existing set.

.EXAMPLE
Update-DevOpsTestConfiguration -Organization 'myorg' -ProjectName 'MyProject' -TestConfigurationId 1 -Name 'Windows 11 + Edge'
#>
Function Update-DevOpsTestConfiguration
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
        [Int]$TestConfigurationId,

        [Parameter(Mandatory = $true)]
        [String]$Name,

        [Parameter()]
        [String]$Description,

        [Parameter()]
        [System.Boolean]$IsDefault,

        [Parameter()]
        [String]$State,

        [Parameter()]
        [HashTable[]]$Values,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/configurations/{2}?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $TestConfigurationId, $ApiVersion

    $body = @{ name = $Name }

    if ($PSBoundParameters.ContainsKey('Description')) { $body.description = $Description }
    if ($PSBoundParameters.ContainsKey('IsDefault'))    { $body.isDefault = [bool]$IsDefault }
    if (-not [String]::IsNullOrWhiteSpace($State))      { $body.state = $State }
    if ($PSBoundParameters.ContainsKey('Values'))       { $body.values = @($Values) }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PATCH' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        throw "[Update-DevOpsTestConfiguration] Failed to update test configuration '$Name' (id $TestConfigurationId) in project '$ProjectName'. Error: $_"
    }
}
