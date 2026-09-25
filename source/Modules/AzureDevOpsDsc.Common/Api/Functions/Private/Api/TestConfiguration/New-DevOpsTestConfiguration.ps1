<#
.SYNOPSIS
Creates a test configuration.

.DESCRIPTION
Creates a test configuration via the Azure DevOps Test Plan API.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the configuration to create.

.PARAMETER Description
A description of the configuration.

.PARAMETER IsDefault
Whether new test plans/suites should use this configuration by default.

.PARAMETER State
'active' or 'inactive'.

.PARAMETER Values
The variable/value pairs, as hashtables: @{ name = 'Browser'; value = 'Edge' }.

.EXAMPLE
New-DevOpsTestConfiguration -Organization 'myorg' -ProjectName 'MyProject' -Name 'Windows 11 + Edge' -Values $values
#>
Function New-DevOpsTestConfiguration
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
        [String]$Name,

        [Parameter()]
        [String]$Description,

        [Parameter()]
        [Switch]$IsDefault,

        [Parameter()]
        [String]$State,

        [Parameter()]
        [HashTable[]]$Values,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/configurations?api-version={2}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $ApiVersion

    $body = @{
        name      = $Name
        isDefault = [bool]$IsDefault.IsPresent
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $body.description = $Description }
    if (-not [String]::IsNullOrWhiteSpace($State))      { $body.state = $State }
    if ($Values.Count -gt 0)                             { $body.values = @($Values) }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        throw "[New-DevOpsTestConfiguration] Failed to create test configuration '$Name' in project '$ProjectName'. Error: $_"
    }
}
