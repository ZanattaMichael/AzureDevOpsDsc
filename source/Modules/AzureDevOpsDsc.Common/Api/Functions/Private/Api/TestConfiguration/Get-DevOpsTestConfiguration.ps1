<#
.SYNOPSIS
Retrieves test configurations for a project.

.DESCRIPTION
Calls the Azure DevOps Test Plan API's configurations endpoint. The API has no get-by-name
lookup, so this lists every configuration in the project and filters client-side when a Name
is supplied. Returns $null when Name is supplied and no configuration matches, rather than
throwing, so callers can treat "not found" as a normal Get() outcome.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
When supplied, returns the single configuration with this name (or $null). When omitted,
returns every configuration in the project.

.EXAMPLE
Get-DevOpsTestConfiguration -Organization 'myorg' -ProjectName 'MyProject' -Name 'Windows 11 + Edge'
#>
Function Get-DevOpsTestConfiguration
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProjectName,

        [Parameter()]
        [String]$Name,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/configurations?api-version={2}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $ApiVersion

    try
    {
        $response = Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET'
    }
    catch
    {
        throw "[Get-DevOpsTestConfiguration] Failed to list test configurations in project '$ProjectName'. Error: $_"
    }

    $configurations = @($response.value)

    if ($PSBoundParameters.ContainsKey('Name') -and (-not [String]::IsNullOrWhiteSpace($Name)))
    {
        return ($configurations | Where-Object { $_.name -eq $Name } | Select-Object -First 1)
    }

    return $configurations
}
