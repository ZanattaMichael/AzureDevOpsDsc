<#
.SYNOPSIS
Creates a classic Release folder.

.DESCRIPTION
Creates a Release folder at the given path via the 'vsrm.dev.azure.com' host. The path is sent
in the body of a POST, not as a query parameter as Build folders take it. As with Build folders,
missing ancestors are expected to be created implicitly; only a single-level path is exercised by
the integration test.

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

    # Unlike Build folders (PUT with ?path=), a Release folder is created by a POST that carries
    # the path in the body; the service answers 405 to PUT.
    $uri = 'https://vsrm.dev.azure.com/{0}/{1}/_apis/release/folders?api-version={2}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $ApiVersion

    $body = @{ path = $normalizedPath }
    if (-not [String]::IsNullOrWhiteSpace($Description)) { $body.description = $Description }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 5))
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
