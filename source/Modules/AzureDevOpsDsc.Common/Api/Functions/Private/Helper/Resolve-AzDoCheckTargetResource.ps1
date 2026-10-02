<#
.SYNOPSIS
Resolves the id of the resource a pipeline check configuration attaches to.

.DESCRIPTION
AzDoCheckConfiguration addresses its target by name (an environment, repository, service
connection, agent queue, variable group or secure file name), but the checks/configurations API
addresses it by id. This helper does the name-to-id resolution for every ResourceType the resource
supports, checking the relevant Live* cache first and falling back to a live API lookup on a cache
miss (caching the result so a later call in the same run does not repeat the lookup).

'queue' is resolved to the PROJECT queue id (distributedtask/queues), not the org-level agent pool
id - the Checks API attaches to the queue, not the pool it draws from.

The resource.type strings sent to the API ('environment', 'repository', 'endpoint', 'queue',
'variablegroup', 'securefile') are the caller's ResourceType value, unchanged. See
https://learn.microsoft.com/en-us/rest/api/azure/devops/approvalsandchecks/check-configurations/add?view=azure-devops-rest-7.1
and https://learn.microsoft.com/en-us/azure/devops/pipelines/process/approvals?view=azure-devops
(protected resources) for the confirmed set of values.

.PARAMETER ProjectName
The name of the Azure DevOps project the resource lives in.

.PARAMETER ResourceType
The kind of resource to resolve: environment, repository, endpoint, queue, variablegroup or
securefile.

.PARAMETER TargetResourceName
The name of the resource to resolve to an id.

.OUTPUTS
A hashtable with:
  Id     - the resolved resource id as a string, or $null when it could not be resolved
  Object - the resolved resource object from the cache/API, or $null

.EXAMPLE
Resolve-AzDoCheckTargetResource -ProjectName 'Contoso' -ResourceType 'queue' -TargetResourceName 'Production'
#>
Function Resolve-AzDoCheckTargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$ResourceType,

        [Parameter(Mandatory = $true)]
        [System.String]$TargetResourceName
    )

    $result = @{ Id = $null; Object = $null }
    $OrgName = Get-AzDoOrganizationName

    switch ($ResourceType)
    {
        'environment'
        {
            $cacheKey = '{0}\{1}' -f $ProjectName, $TargetResourceName
            $obj = Get-CacheItem -Key $cacheKey -Type 'LivePipelineEnvironments'
            if (-not $obj)
            {
                Write-Verbose "[Resolve-AzDoCheckTargetResource] Environment '$TargetResourceName' not in cache — falling back to live API lookup."
                $all = List-DevOpsPipelineEnvironments -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
                $obj = $all | Where-Object { $_.name -eq $TargetResourceName } | Select-Object -First 1
                if ($obj) { Add-CacheItem -Key $cacheKey -Value $obj -Type 'LivePipelineEnvironments' }
            }
            if ($obj) { $result.Object = $obj; $result.Id = $obj.id.ToString() }
        }
        'repository'
        {
            $cacheKey = '{0}\{1}' -f $ProjectName, $TargetResourceName
            $obj = Get-CacheItem -Key $cacheKey -Type 'LiveRepositories'
            if ($obj) { $result.Object = $obj; $result.Id = $obj.id }
        }
        'endpoint'
        {
            $cacheKey = '{0}\{1}' -f $ProjectName, $TargetResourceName
            $obj = Get-CacheItem -Key $cacheKey -Type 'LiveServiceConnections'
            if ($obj) { $result.Object = $obj; $result.Id = $obj.id }
        }
        'queue'
        {
            # Resolve to the PROJECT queue id (distributedtask/queues), not the org-level pool id -
            # see AzDoAgentQueue, which creates/caches the same object under the same key.
            $cacheKey = '{0}\{1}' -f $ProjectName, $TargetResourceName
            $obj = Get-CacheItem -Key $cacheKey -Type 'LiveAgentQueues'
            if (-not $obj)
            {
                Write-Verbose "[Resolve-AzDoCheckTargetResource] Queue '$TargetResourceName' not in cache — falling back to live API lookup."
                $all = List-DevOpsAgentQueues -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
                $obj = $all | Where-Object { $_.name -eq $TargetResourceName } | Select-Object -First 1
                if ($obj) { Add-CacheItem -Key $cacheKey -Value $obj -Type 'LiveAgentQueues' }
            }
            if ($obj) { $result.Object = $obj; $result.Id = $obj.id.ToString() }
        }
        'variablegroup'
        {
            $cacheKey = '{0}\{1}' -f $ProjectName, $TargetResourceName
            $obj = Get-CacheItem -Key $cacheKey -Type 'LiveVariableGroups'
            if (-not $obj)
            {
                Write-Verbose "[Resolve-AzDoCheckTargetResource] Variable group '$TargetResourceName' not in cache — falling back to live API lookup."
                $all = List-DevOpsVariableGroups -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
                $obj = $all | Where-Object { $_.name -eq $TargetResourceName } | Select-Object -First 1
                if ($obj) { Add-CacheItem -Key $cacheKey -Value $obj -Type 'LiveVariableGroups' }
            }
            if ($obj) { $result.Object = $obj; $result.Id = $obj.id.ToString() }
        }
        'securefile'
        {
            $cacheKey = '{0}\{1}' -f $ProjectName, $TargetResourceName
            $obj = Get-CacheItem -Key $cacheKey -Type 'LiveSecureFiles'
            if (-not $obj)
            {
                Write-Verbose "[Resolve-AzDoCheckTargetResource] Secure file '$TargetResourceName' not in cache — falling back to live API lookup."
                $all = List-DevOpsSecureFiles -Organization $OrgName -ProjectName $ProjectName
                $obj = $all | Where-Object { $_.name -eq $TargetResourceName } | Select-Object -First 1
                if ($obj) { Add-CacheItem -Key $cacheKey -Value $obj -Type 'LiveSecureFiles' }
            }
            if ($obj) { $result.Object = $obj; $result.Id = $obj.id }
        }
        default
        {
            # Unknown ResourceType (the DSC class's ValidateSet already blocks this - only reachable
            # calling the function directly). Treat the name as the id rather than failing outright.
            $result.Id = $TargetResourceName
        }
    }

    return $result
}
