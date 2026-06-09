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
    $scCache      = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ConnectionName) -Type 'LiveServiceConnections'

    if (-not $projectCache) { $getResult.status = [DSCGetSummaryState]::Error; $getResult.reason = "Project not found."; return $getResult }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $namespace) { $getResult.status = [DSCGetSummaryState]::Error; return $getResult }

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
