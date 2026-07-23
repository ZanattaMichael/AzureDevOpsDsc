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
        Write-Verbose "[Get-AzDoProjectPermission] Project '$ProjectName' not in cache — falling back to live API lookup."
        $projectCache = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($projectCache) { Add-CacheItem -Key $ProjectName -Value $projectCache -Type 'LiveProjects' }
    }
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
    # Use exact-match (-eq) so child tokens (e.g. BoardGroup sub-paths) are not included.
    $DevOpsACLs = $DevOpsACLs | Where-Object { $_.token -eq $projectToken }

    # Wrap in @() so $DifferenceACLs is always an array; ConvertTo-FormattedACL returns a
    # generic List that PowerShell unrolls to a bare hashtable when there is only one entry,
    # making [0] indexing in Test-ACLListforChanges return $null.
    $DifferenceACLs = @($DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName)

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

    # Wrap in @() so $ReferenceACLs is always an array; Test-ACLListforChanges uses [0] indexing
    # and a raw hashtable returns $null at index 0.
    $ReferenceACLs = @(ConvertTo-ACL @params | Where-Object { $_.token.Type -ne 'ProjectUnknown' })

    # The Project namespace has protected system-group ACEs (Project Admins, Contributors, etc.)
    # that Azure DevOps auto-creates and cannot remove. Comparing the full ACL count would always
    # fail. Instead, filter DifferenceACLs.aces to only the identities we are managing so that
    # Test-ACLListforChanges compares only the relevant ACE(s).
    if ($ReferenceACLs.Count -gt 0 -and $DifferenceACLs.Count -gt 0) {
        $desiredOriginIds = @($ReferenceACLs[0].aces | ForEach-Object { $_.Identity.value.originId } | Where-Object { $_ })
        if ($desiredOriginIds.Count -gt 0) {
            $DifferenceACLs[0]['aces'] = @($DifferenceACLs[0].aces | Where-Object { $_.Identity.value.originId -in $desiredOriginIds })
        } else {
            # No desired identities (empty permissions) — treat live as having no relevant ACEs.
            $DifferenceACLs[0]['aces'] = @()
        }
    }

    # The Project namespace's START_BUILD (bit 32) Deny is platform-managed for at least one identity
    # here, not something our Set ever requests either way: confirmed across three independent live
    # Set runs that a byte-correct payload (wire-captured), even preceded by an explicit DELETE of the
    # whole ACE, always results in a live Deny that includes this extra bit a few seconds later -
    # despite our payload never mentioning it. Identities that explicitly want it (e.g. Release
    # Managers requests START_BUILD: Allow) are unaffected since Allow/Deny are compared separately.
    # Strip it from the live side only, so we stop fighting a bit we don't manage - same rationale as
    # ConvertTo-ACETokenList's reserved-bit stripping for Process/ReadProcessPermissions.
    foreach ($ace in $DifferenceACLs[0].aces)
    {
        if ($ace.Permissions.Deny)
        {
            $ace.Permissions.Deny = @($ace.Permissions.Deny | Where-Object { $_.bit -ne 32 })
        }
    }

    $compareResult = Test-ACLListforChanges -ReferenceACLs $ReferenceACLs -DifferenceACLs $DifferenceACLs

    $getResult.propertiesChanged = $compareResult.propertiesChanged
    $getResult.status = [DSCGetSummaryState]::"$($compareResult.status)"
    $getResult.reason = $compareResult.reason
    $getResult.ReferenceACLs  = $ReferenceACLs
    $getResult.DifferenceACLs = $DifferenceACLs

    return $getResult
}
