Function Get-AzDoServiceConnectionPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$ConnectionName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoServiceConnectionPermission] Started."

    $SecurityNamespace = 'ServiceEndpoints'
    $OrganizationName  = (Get-AzDoOrganizationName)

    $getResult = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null; reason = $null }

    $projectCache = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    if (-not $projectCache)
    {
        Write-Verbose "[Get-AzDoServiceConnectionPermission] Project '$ProjectName' not in cache — falling back to live API lookup."
        $projectCache = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($projectCache) { Add-CacheItem -Key $ProjectName -Value $projectCache -Type 'LiveProjects' }
    }
    if (-not $projectCache) { $getResult.status = [DSCGetSummaryState]::Error; $getResult.reason = "Project not found."; return $getResult }

    $scCacheKey = '{0}\{1}' -f $ProjectName, $ConnectionName
    $scCache    = Get-CacheItem -Key $scCacheKey -Type 'LiveServiceConnections'
    if (-not $scCache)
    {
        Write-Verbose "[Get-AzDoServiceConnectionPermission] Service connection '$ConnectionName' not in cache — falling back to live API lookup."
        $allSCs  = List-DevOpsServiceConnections -ApiUri "https://dev.azure.com/$OrganizationName" -ProjectName $ProjectName
        $scCache = $allSCs | Where-Object { $_.name -eq $ConnectionName } | Select-Object -First 1
        if ($scCache) { Add-CacheItem -Key $scCacheKey -Value $scCache -Type 'LiveServiceConnections' }
    }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $namespace) { Write-Error "[Get-AzDoServiceConnectionPermission] Security namespace not found."; $getResult.status = [DSCGetSummaryState]::Error; return $getResult }

    $getResult.namespace = $namespace

    $DevOpsACLs     = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId
    $DifferenceACLs = $DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName

    if ($scCache)
    {
        $DifferenceACLs = $DifferenceACLs | Where-Object {
            ($_.Token.Type -eq 'ServiceEndpoints') -and ($_.Token.ProjectId -eq $projectCache.id) -and ($_.Token.EndpointId -eq $scCache.id)
        }
    }
    else
    {
        $DifferenceACLs = $DifferenceACLs | Where-Object {
            ($_.Token.Type -eq 'ServiceEndpoints') -and ($_.Token.ProjectId -eq $projectCache.id) -and (-not $_.Token.EndpointId)
        }
    }

    $tokenName = if ($scCache) {
        'endpoints/Project/{0}/endpoint/{1}' -f $ProjectName, $ConnectionName
    } else {
        'endpoints/Project/{0}' -f $ProjectName
    }

    $params = @{
        Permissions       = $Permissions
        SecurityNamespace = $SecurityNamespace
        isInherited       = $isInherited
        OrganizationName  = $OrganizationName
        TokenName         = $tokenName
    }

    $ReferenceACLs = ConvertTo-ACL @params

    $compareResult = Test-ACLListforChanges -ReferenceACLs $ReferenceACLs -DifferenceACLs $DifferenceACLs
    $getResult.propertiesChanged = $compareResult.propertiesChanged
    $getResult.status = [DSCGetSummaryState]::"$($compareResult.status)"
    $getResult.reason = $compareResult.reason
    $getResult.ReferenceACLs  = $ReferenceACLs
    $getResult.DifferenceACLs = $DifferenceACLs

    return $getResult
}
