<#
.SYNOPSIS
Resolves the id the pipelinePermissions API expects for a protected Azure DevOps resource.

.DESCRIPTION
The pipelinePermissions REST API addresses every protected resource type by id rather than by
name. This helper resolves TargetResourceName through the same Live* cache each resource type's own
Get-AzDo* function reads (LiveServiceConnections, LiveAgentQueues, LiveVariableGroups,
LiveSecureFiles, LivePipelineEnvironments, LiveRepositories), falling back to a live API listing on
a cache miss so a resource created earlier in the same configuration apply is still found. For
'repository' the id is composed as "{projectId}.{repositoryId}" - the pipelinePermissions API's own
convention, not this module's - which is why it needs the project id as well as the repository id.

Returns $null when the resource cannot be found, rather than throwing, so callers can report a
clear NotFound/Error status instead of an unhandled exception.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER ResourceType
One of 'endpoint', 'queue', 'variablegroup', 'securefile', 'environment', 'repository'.

.PARAMETER TargetResourceName
The protected resource's display name.

.EXAMPLE
Resolve-AzDoPipelineAuthorizationResource -ProjectName 'MyProject' -ResourceType 'variablegroup' -TargetResourceName 'Prod Secrets'
#>
function Resolve-AzDoPipelineAuthorizationResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('endpoint', 'queue', 'variablegroup', 'securefile', 'environment', 'repository')]
        [string]$ResourceType,

        [Parameter(Mandatory = $true)]
        [string]$TargetResourceName
    )

    $OrgName  = Get-AzDoOrganizationName
    $ApiUri   = "https://dev.azure.com/$OrgName"
    $cacheKey = '{0}\{1}' -f $ProjectName, $TargetResourceName

    switch ($ResourceType)
    {
        'endpoint'
        {
            $item = Get-CacheItem -Key $cacheKey -Type 'LiveServiceConnections'
            if (-not $item)
            {
                Write-Verbose "[Resolve-AzDoPipelineAuthorizationResource] Service connection '$TargetResourceName' not in cache — falling back to live API lookup."
                $item = List-DevOpsServiceConnections -ApiUri $ApiUri -ProjectName $ProjectName | Where-Object { $_.name -eq $TargetResourceName } | Select-Object -First 1
                if ($item) { Add-CacheItem -Key $cacheKey -Value $item -Type 'LiveServiceConnections' -SuppressWarning }
            }
            if ($item) { return $item.id.ToString() }
        }

        'queue'
        {
            $item = Get-CacheItem -Key $cacheKey -Type 'LiveAgentQueues'
            if (-not $item)
            {
                Write-Verbose "[Resolve-AzDoPipelineAuthorizationResource] Agent queue '$TargetResourceName' not in cache — falling back to live API lookup."
                $item = List-DevOpsAgentQueues -ApiUri $ApiUri -ProjectName $ProjectName | Where-Object { $_.name -eq $TargetResourceName } | Select-Object -First 1
                if ($item) { Add-CacheItem -Key $cacheKey -Value $item -Type 'LiveAgentQueues' -SuppressWarning }
            }
            if ($item) { return $item.id.ToString() }
        }

        'variablegroup'
        {
            $item = Get-CacheItem -Key $cacheKey -Type 'LiveVariableGroups'
            if (-not $item)
            {
                Write-Verbose "[Resolve-AzDoPipelineAuthorizationResource] Variable group '$TargetResourceName' not in cache — falling back to live API lookup."
                $item = List-DevOpsVariableGroups -ApiUri $ApiUri -ProjectName $ProjectName | Where-Object { $_.name -eq $TargetResourceName } | Select-Object -First 1
                if ($item) { Add-CacheItem -Key $cacheKey -Value $item -Type 'LiveVariableGroups' -SuppressWarning }
            }
            if ($item) { return $item.id.ToString() }
        }

        'securefile'
        {
            $item = Get-CacheItem -Key $cacheKey -Type 'LiveSecureFiles'
            if (-not $item)
            {
                Write-Verbose "[Resolve-AzDoPipelineAuthorizationResource] Secure file '$TargetResourceName' not in cache — falling back to live API lookup."
                $item = List-DevOpsSecureFiles -Organization $OrgName -ProjectName $ProjectName | Where-Object { $_.name -eq $TargetResourceName } | Select-Object -First 1
                if ($item) { Add-CacheItem -Key $cacheKey -Value $item -Type 'LiveSecureFiles' -SuppressWarning }
            }
            if ($item) { return $item.id.ToString() }
        }

        'environment'
        {
            $item = Get-CacheItem -Key $cacheKey -Type 'LivePipelineEnvironments'
            if (-not $item)
            {
                Write-Verbose "[Resolve-AzDoPipelineAuthorizationResource] Environment '$TargetResourceName' not in cache — falling back to live API lookup."
                $item = List-DevOpsPipelineEnvironments -ApiUri $ApiUri -ProjectName $ProjectName | Where-Object { $_.name -eq $TargetResourceName } | Select-Object -First 1
                if ($item) { Add-CacheItem -Key $cacheKey -Value $item -Type 'LivePipelineEnvironments' -SuppressWarning }
            }
            if ($item) { return $item.id.ToString() }
        }

        'repository'
        {
            $repo = Get-CacheItem -Key $cacheKey -Type 'LiveRepositories'
            if (-not $repo)
            {
                Write-Verbose "[Resolve-AzDoPipelineAuthorizationResource] Repository '$TargetResourceName' not in cache — falling back to live API lookup."
                $repo = List-DevOpsGitRepository -OrganizationName $OrgName -ProjectName $ProjectName | Where-Object { $_.name -eq $TargetResourceName } | Select-Object -First 1
                if ($repo) { Add-CacheItem -Key $cacheKey -Value $repo -Type 'LiveRepositories' -SuppressWarning }
            }
            if ($repo)
            {
                $project = Resolve-AzDoProject -ProjectName $ProjectName
                if ($project) { return ('{0}.{1}' -f $project.id, $repo.id) }
            }
        }
    }

    Write-Verbose "[Resolve-AzDoPipelineAuthorizationResource] Resource '$TargetResourceName' of type '$ResourceType' was not found in project '$ProjectName'."
    return $null
}
