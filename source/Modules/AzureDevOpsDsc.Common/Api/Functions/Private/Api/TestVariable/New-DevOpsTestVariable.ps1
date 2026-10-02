<#
.SYNOPSIS
Creates a test plan variable.

.DESCRIPTION
Creates a test variable via the Azure DevOps Test Plan API.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the variable to create.

.PARAMETER Description
A description of the variable.

.PARAMETER Values
The allowed values for the variable.

.EXAMPLE
New-DevOpsTestVariable -Organization 'myorg' -ProjectName 'MyProject' -Name 'Browser' -Values @('Edge', 'Chrome')
#>
Function New-DevOpsTestVariable
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
        [String[]]$Values,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/variables?api-version={2}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $ApiVersion

    $body = @{ name = $Name }

    if ($PSBoundParameters.ContainsKey('Description')) { $body.description = $Description }
    if ($Values.Count -gt 0)                            { $body.values = @($Values) }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        throw "[New-DevOpsTestVariable] Failed to create test variable '$Name' in project '$ProjectName'. Error: $_"
    }
}
