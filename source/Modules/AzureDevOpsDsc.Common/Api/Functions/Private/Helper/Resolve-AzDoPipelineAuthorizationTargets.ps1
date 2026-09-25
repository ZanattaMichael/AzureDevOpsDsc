<#
.SYNOPSIS
Resolves pipeline folder paths to their pipeline definition ids for the pipelinePermissions API.

.DESCRIPTION
AuthorizedPipelines is expressed as full pipeline paths (e.g. '\Platform\deploy-infra') rather
than bare names because the LivePipelines cache is keyed on '{ProjectName}\{PipelineName}' alone -
two pipelines with the same name in different folders would otherwise be ambiguous. This splits
each path into its folder and leaf name, matches the leaf name against the cache, and - unlike the
bare cache lookups elsewhere in this module - confirms the cached candidate's own folder (through
Format-AzDoPipelineFolderPath, so '\Platform' and 'Platform\' compare equal) before accepting it.
A cache miss or folder mismatch falls back to a single live List-DevOpsPipelines call shared across
every path being resolved in this invocation, re-caching whatever it matches.

A path that cannot be resolved to exactly one pipeline is still returned, with a $null Id, so the
caller can report a clear per-path error rather than have the entry silently disappear.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER PipelinePaths
The pipeline paths to resolve, e.g. '\Platform\deploy-infra'. A root pipeline may be given as just
its name.

.EXAMPLE
Resolve-AzDoPipelineAuthorizationTargets -ProjectName 'MyProject' -PipelinePaths @('\Platform\deploy-infra')
#>
function Resolve-AzDoPipelineAuthorizationTargets
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $true)]
        [string[]]$PipelinePaths
    )

    $OrgName     = Get-AzDoOrganizationName
    $ApiUri      = "https://dev.azure.com/$OrgName"
    $liveFetched = $false
    $liveList    = @()

    $results = [System.Collections.Generic.List[Object]]::new()

    foreach ($path in $PipelinePaths)
    {
        $normalized = Format-AzDoPipelineFolderPath -Path $path
        $segments   = @($normalized.Trim('\') -split '\\')
        $leafName   = $segments[-1]
        $folder     = if ($segments.Count -gt 1) { '\' + ($segments[0..($segments.Count - 2)] -join '\') } else { '\' }

        $cacheKey  = '{0}\{1}' -f $ProjectName, $leafName
        $candidate = Get-CacheItem -Key $cacheKey -Type 'LivePipelines'

        $matched = $null
        if ($candidate -and (Format-AzDoPipelineFolderPath -Path $candidate.folder) -eq $folder)
        {
            $matched = $candidate
        }

        if (-not $matched)
        {
            if (-not $liveFetched)
            {
                Write-Verbose "[Resolve-AzDoPipelineAuthorizationTargets] Pipeline path '$path' not confirmed in cache — falling back to live API lookup."
                $liveList    = @(List-DevOpsPipelines -ApiUri $ApiUri -ProjectName $ProjectName)
                $liveFetched = $true
            }

            $matched = $liveList | Where-Object {
                $_.name -eq $leafName -and (Format-AzDoPipelineFolderPath -Path $_.folder) -eq $folder
            } | Select-Object -First 1

            if ($matched)
            {
                Add-CacheItem -Key $cacheKey -Value $matched -Type 'LivePipelines' -SuppressWarning
            }
        }

        $results.Add(
            @{
                Path = $path
                Id   = if ($matched) { $matched.id } else { $null }
            }
        )
    }

    return $results.ToArray()
}
