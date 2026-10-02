<#
.SYNOPSIS
Updates a test plan variable.

.DESCRIPTION
PATCHes a test variable via the Azure DevOps Test Plan API, addressed by id. The API
requires 'name' on every PATCH even when the name itself is not changing.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TestVariableId
The id of the variable to update.

.PARAMETER Name
The variable's name.

.PARAMETER Description
A new description.

.PARAMETER Values
New allowed values. Replaces the existing set.

.EXAMPLE
Update-DevOpsTestVariable -Organization 'myorg' -ProjectName 'MyProject' -TestVariableId 1 -Name 'Browser' -Values @('Edge')
#>
Function Update-DevOpsTestVariable
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
        [Int]$TestVariableId,

        [Parameter(Mandatory = $true)]
        [String]$Name,

        [Parameter()]
        [String]$Description,

        [Parameter()]
        [String[]]$Values,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/variables/{2}?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $TestVariableId, $ApiVersion

    $body = @{ name = $Name }

    if ($PSBoundParameters.ContainsKey('Description')) { $body.description = $Description }
    if ($PSBoundParameters.ContainsKey('Values'))       { $body.values = @($Values) }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PATCH' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        throw "[Update-DevOpsTestVariable] Failed to update test variable '$Name' (id $TestVariableId) in project '$ProjectName'. Error: $_"
    }
}
