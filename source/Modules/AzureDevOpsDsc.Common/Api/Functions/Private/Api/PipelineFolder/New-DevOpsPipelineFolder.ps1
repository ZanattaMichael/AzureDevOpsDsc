<#
.SYNOPSIS
Creates a pipeline (build) folder.

.DESCRIPTION
Creates a build folder at the given path. Unlike the work item query tree, the Build folders API
creates missing ancestors implicitly, so a nested path can be created in one call.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The full path of the folder, for example '\Platform\Release'.

.PARAMETER Description
An optional description.

.EXAMPLE
New-DevOpsPipelineFolder -Organization 'myorg' -ProjectName 'MyProject' -Path '\Platform'
#>
Function New-DevOpsPipelineFolder
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

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/build/folders?path={2}&api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($normalizedPath), $ApiVersion

    $body = @{ path = $normalizedPath }
    if (-not [String]::IsNullOrWhiteSpace($Description)) { $body.description = $Description }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PUT' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        Write-Error "[New-DevOpsPipelineFolder] Failed to create pipeline folder '$normalizedPath' in project '$ProjectName'. Error: $_"
        return $null
    }
}
