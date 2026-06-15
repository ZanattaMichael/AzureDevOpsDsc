Function Get-AzDoVariableGroupPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$VariableGroupName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoVariableGroupPermission] Started."

    $SecurityNamespace = 'Library'
    $OrganizationName  = (Get-AzDoOrganizationName)

    $getResult = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null; reason = $null }

    $projectCache = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    if (-not $projectCache)
    {
        Write-Verbose "[Get-AzDoVariableGroupPermission] Project '$ProjectName' not in cache — falling back to live API lookup."
        $projectCache = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($projectCache) { Add-CacheItem -Key $ProjectName -Value $projectCache -Type 'LiveProjects' }
    }
    if (-not $projectCache)
    {
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "Project not found: $ProjectName"
        return $getResult
    }

    $vgCacheKey = '{0}\{1}' -f $ProjectName, $VariableGroupName
    $vgCache    = Get-CacheItem -Key $vgCacheKey -Type 'LiveVariableGroups'
    if (-not $vgCache)
    {
        Write-Verbose "[Get-AzDoVariableGroupPermission] Variable group '$VariableGroupName' not in cache — falling back to live API lookup."
        $allVGs  = List-DevOpsVariableGroups -ApiUri "https://dev.azure.com/$OrganizationName" -ProjectName $ProjectName
        $vgCache = $allVGs | Where-Object { $_.name -eq $VariableGroupName } | Select-Object -First 1
        if ($vgCache) { Add-CacheItem -Key $vgCacheKey -Value $vgCache -Type 'LiveVariableGroups' }
    }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $namespace) { Write-Error "[Get-AzDoVariableGroupPermission] Security namespace not found."; $getResult.status = [DSCGetSummaryState]::Error; return $getResult }

    $getResult.namespace = $namespace

    $DevOpsACLs     = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId
    $DifferenceACLs = $DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName

    if ($vgCache)
    {
        $DifferenceACLs = $DifferenceACLs | Where-Object {
            ($_.Token.Type -eq 'Library') -and ($_.Token.ProjectId -eq $projectCache.id) -and ($_.Token.VariableGroupId -eq $vgCache.id)
        }
    }
    else
    {
        $DifferenceACLs = $DifferenceACLs | Where-Object {
            ($_.Token.Type -eq 'Library') -and ($_.Token.ProjectId -eq $projectCache.id) -and (-not $_.Token.VariableGroupId)
        }
    }

    $tokenName = if ($vgCache) {
        'Library/Project/{0}/VariableGroup/{1}' -f $ProjectName, $VariableGroupName
    } else {
        'Library/Project/{0}' -f $ProjectName
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
