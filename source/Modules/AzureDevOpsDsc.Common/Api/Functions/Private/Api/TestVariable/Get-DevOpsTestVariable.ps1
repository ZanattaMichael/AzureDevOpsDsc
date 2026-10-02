<#
.SYNOPSIS
Retrieves test plan variables for a project.

.DESCRIPTION
Calls the Azure DevOps Test Plan API's variables endpoint. The API has no get-by-name
lookup, so this lists every variable in the project and filters client-side when a Name is
supplied. Returns $null when Name is supplied and no variable matches, rather than throwing,
so callers can treat "not found" as a normal Get() outcome.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
When supplied, returns the single variable with this name (or $null). When omitted, returns
every variable in the project.

.EXAMPLE
Get-DevOpsTestVariable -Organization 'myorg' -ProjectName 'MyProject' -Name 'Browser'
#>
Function Get-DevOpsTestVariable
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

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/variables?api-version={2}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $ApiVersion

    try
    {
        $response = Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET'
    }
    catch
    {
        throw "[Get-DevOpsTestVariable] Failed to list test variables in project '$ProjectName'. Error: $_"
    }

    $variables = @($response.value)

    if ($PSBoundParameters.ContainsKey('Name') -and (-not [String]::IsNullOrWhiteSpace($Name)))
    {
        return ($variables | Where-Object { $_.name -eq $Name } | Select-Object -First 1)
    }

    return $variables
}
