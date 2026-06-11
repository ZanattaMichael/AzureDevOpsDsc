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

    # We build the ACL token from the project GUID. If the id is missing we CANNOT build a valid
    # token — querying with a malformed token would silently return empty and be misread as
    # "no permissions". Fail loudly here instead of guessing.
    if (-not $projectCache.id)
    {
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "Could not resolve project id for '$ProjectName'; cannot build ACL token."
        return $getResult
    }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $namespace)
    {
        Write-Error "[Get-AzDoProjectPermission] Security namespace not found."
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "Security namespace '$SecurityNamespace' not found."
        return $getResult
    }

    $getResult.namespace = $namespace

    # Build the project's ACL token once from the resolved GUID; reused below for both the
    # client-side filter and the reference ACL (single source of truth).
    # NOTE: server-side filtering via Get-DevOpsACL -Token was attempted but the accesscontrollists
    # '?token=' query returns empty for this namespace (exact token-encoding format unverified), so
    # we filter client-side. The expensive part — per-ACE identity resolution in ConvertTo-FormattedACL
    # — is still skipped for non-target ACLs, which is where the ~40x speed-up comes from.
    $projectToken = '$PROJECT:vstfs:///Classification/TeamProject/{0}' -f $projectCache.id

    $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId
    if (-not $DevOpsACLs)
    {
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "No ACLs found."
        return $getResult
    }

    # Filter the raw ACLs to just the target project's token BEFORE the expensive formatting.
    $projectTokenPattern = $LocalizedDataAzSerializationPatten.ProjectPermission -f $projectCache.id
    $DevOpsACLs = $DevOpsACLs | Where-Object { $_.token -match $projectTokenPattern }

    $DifferenceACLs = $DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName

    # The reference token must use the project GUID, exactly like the live ACL token. Using the
    # project *name* fails the project token regex (it does not allow underscores) and resolves to
    # 'ProjectUnknown', so reference and difference never match.
    $params = @{
        Permissions       = $Permissions
        SecurityNamespace = $SecurityNamespace
        isInherited       = $isInherited
        OrganizationName  = $OrganizationName
        TokenName         = $projectToken
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
