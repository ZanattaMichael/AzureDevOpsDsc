Function Get-AzDoProjectPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoProjectPermission] Started."

    $SecurityNamespace = 'Project'
    $OrganizationName  = (Get-AzDoOrganizationName)

    $getResult = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        project           = $ProjectName
        groupName         = $GroupName
        status            = $null
        reason            = $null
    }

    $projectCache = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
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

    $ACLLookupParams = @{
        OrganizationName     = $OrganizationName
        SecurityDescriptorId = $namespace.namespaceId
    }

    $DevOpsACLs = Get-DevOpsACL @ACLLookupParams
    if (-not $DevOpsACLs)
    {
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "No ACLs found."
        return $getResult
    }

    $DifferenceACLs = $DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName
    $DifferenceACLs = $DifferenceACLs | Where-Object {
        ($_.Token.Type -eq 'ProjectPermission') -and ($_.Token.ProjectId -eq $projectCache.id)
    }

    $params = @{
        Permissions       = $Permissions
        SecurityNamespace = $SecurityNamespace
        isInherited       = $isInherited
        OrganizationName  = $OrganizationName
        TokenName         = '$PROJECT:vstfs:///Classification/TeamProject/{0}' -f $ProjectName
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
