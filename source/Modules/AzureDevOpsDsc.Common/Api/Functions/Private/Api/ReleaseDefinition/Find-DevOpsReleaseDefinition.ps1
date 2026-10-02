<#
.SYNOPSIS
Finds a classic Release definition by exact name.

.DESCRIPTION
Resolves a Release definition name to its numeric id and folder path, using the 'release/
definitions' search endpoint's exact-name-match filter. Used to build a definition's
'ReleaseManagement' ACL token, which addresses it by id rather than by name.

Returns $null when no definition matches - a legitimate "not found" answer, not a failure - and
throws on any other API error, since a caller resolving a permission token cannot treat a swallowed
error as "there is nothing to protect."

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER DefinitionName
The exact name of the Release definition.

.PARAMETER FolderPath
Optional. Narrows the search to a specific Release folder, for definitions whose name is not
unique across the project.

.EXAMPLE
Find-DevOpsReleaseDefinition -Organization 'myorg' -ProjectName 'MyProject' -DefinitionName 'Platform Release'
#>
Function Find-DevOpsReleaseDefinition
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$DefinitionName,

        [Parameter()]
        [Alias('Path')]
        [System.String]$FolderPath,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://vsrm.dev.azure.com/{0}/{1}/_apis/release/definitions?searchText={2}&isExactNameMatch=true&api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($DefinitionName), $ApiVersion

    try
    {
        $results = @((Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value)
    }
    catch
    {
        if ($_ -match '(?i)does not exist' -or $_ -match '(?i)was not found' -or $_ -match '404')
        {
            return $null
        }

        throw "[Find-DevOpsReleaseDefinition] Failed to search for release definition '$DefinitionName' in project '$ProjectName'. Error: $_"
    }

    if ($results.Count -eq 0)
    {
        return $null
    }

    if (-not [String]::IsNullOrWhiteSpace($FolderPath))
    {
        $normalizedPath = Format-AzDoPipelineFolderPath -Path $FolderPath
        $results = @($results | Where-Object { (Format-AzDoPipelineFolderPath -Path $_.path) -eq $normalizedPath })
    }

    return $results | Select-Object -First 1
}
