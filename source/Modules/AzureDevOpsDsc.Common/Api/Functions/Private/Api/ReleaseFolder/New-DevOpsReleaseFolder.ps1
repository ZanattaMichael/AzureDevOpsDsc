<#
.SYNOPSIS
Creates a classic Release folder.

.DESCRIPTION
Creates a Release folder at the given path via the 'vsrm.dev.azure.com' host. As with Build
folders, missing ancestors are created implicitly, so a nested path can be created in one call.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The full path of the folder, for example '\Platform\Release'.

.PARAMETER Description
An optional description.

.EXAMPLE
New-DevOpsReleaseFolder -Organization 'myorg' -ProjectName 'MyProject' -Path '\Platform'
#>
Function New-DevOpsReleaseFolder
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
        [System.String]$Path,

        [Parameter()]
        [System.String]$Description,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $normalizedPath = Format-AzDoPipelineFolderPath -Path $Path

    $uri = 'https://vsrm.dev.azure.com/{0}/{1}/_apis/release/folders?path={2}&api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($normalizedPath), $ApiVersion

    $body = @{ path = $normalizedPath }
    if (-not [String]::IsNullOrWhiteSpace($Description)) { $body.description = $Description }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PUT' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        # Classic Release Management can be disabled at the organization level (see the
        # 'DisableClassicPipelineCreation' project/organization setting). The service answers a
        # plain 400/403 for that, which reads as an opaque API failure unless we name the cause.
        if ($_ -match '(?i)disabled' -and $_ -match '(?i)classic')
        {
            throw "[New-DevOpsReleaseFolder] Failed to create release folder '$normalizedPath' in project '$ProjectName': classic Release Management (classic pipeline creation) appears to be disabled for this organization or project. Error: $_"
        }

        throw "[New-DevOpsReleaseFolder] Failed to create release folder '$normalizedPath' in project '$ProjectName'. Error: $_"
    }
}
