Function Get-AzDoPipelinePermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$PipelineName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoPipelinePermission] Started."

    $SecurityNamespace = 'Build'
    $OrganizationName  = (Get-AzDoOrganizationName)

    $getResult = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        project           = $ProjectName
        pipelineName      = $PipelineName
        status            = $null
        reason            = $null
    }

    $projectCache  = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    $pipelineCache = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PipelineName) -Type 'LivePipelines'

    if (-not $projectCache)
    {
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "Project not found: $ProjectName"
        return $getResult
    }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $namespace)
    {
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "Security namespace '$SecurityNamespace' not found."
        return $getResult
    }

    $getResult.namespace = $namespace

    $DevOpsACLs     = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId
    $DifferenceACLs = $DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName

    if ($pipelineCache)
    {
        $DifferenceACLs = $DifferenceACLs | Where-Object {
            ($_.Token.Type -eq 'Build') -and ($_.Token.ProjectId -eq $projectCache.id) -and ($_.Token.PipelineId -eq $pipelineCache.id)
        }
    }
    else
    {
        $DifferenceACLs = $DifferenceACLs | Where-Object {
            ($_.Token.Type -eq 'Build') -and ($_.Token.ProjectId -eq $projectCache.id) -and (-not $_.Token.PipelineId)
        }
    }

    $tokenName = if ($pipelineCache) { '{0}/{1}' -f $ProjectName, $PipelineName } else { $ProjectName }

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
