Function Get-AzDoTaggingPermission
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

    Write-Verbose "[Get-AzDoTaggingPermission] Started."

    $SecurityNamespace = 'Tagging'
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
        Write-Verbose "[Get-AzDoTaggingPermission] Project '$ProjectName' not in cache — falling back to live API lookup."
        $projectCache = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($projectCache) { Add-CacheItem -Key $ProjectName -Value $projectCache -Type 'LiveProjects' }
    }
    if (-not $projectCache)
    {
        # A project that no longer exists is NotFound, never Missing - Missing would drive the
        # base class to Remove-, which has nothing meaningful to remove without a project id.
        $getResult.status = [DSCGetSummaryState]::NotFound
        $getResult.reason = "Project not found: $ProjectName"
        return $getResult
    }

    if (-not $projectCache.id)
    {
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "Could not resolve project id for '$ProjectName'; cannot build ACL token."
        return $getResult
    }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $namespace)
    {
        Write-Error "[Get-AzDoTaggingPermission] Security namespace not found." -ErrorAction Continue
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "Security namespace '$SecurityNamespace' not found."
        return $getResult
    }

    $getResult.namespace = $namespace

    # Tagging tokens address the project by id: '/{projectId}'.
    $projectToken = '/{0}' -f $projectCache.id

    $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId
    if (-not $DevOpsACLs)
    {
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "No ACLs found."
        return $getResult
    }

    # Filter to just the target project's token before the expensive per-ACE identity resolution.
    $DevOpsACLs = $DevOpsACLs | Where-Object { $_.token -eq $projectToken }

    # Wrap in @() so $DifferenceACLs is always an array; ConvertTo-FormattedACL returns a
    # generic List that PowerShell unrolls to a bare hashtable when there is only one entry,
    # making [0] indexing in Test-ACLListforChanges return $null.
    $DifferenceACLs = @($DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName)

    $params = @{
        Permissions       = $Permissions
        SecurityNamespace = $SecurityNamespace
        isInherited       = $isInherited
        OrganizationName  = $OrganizationName
        TokenName         = $projectToken
    }

    # Wrap in @() so $ReferenceACLs is always an array; Test-ACLListforChanges uses [0] indexing
    # and a raw hashtable returns $null at index 0.
    $ReferenceACLs = @(ConvertTo-ACL @params | Where-Object { $_.token.Type -ne 'TaggingUnknown' })

    # The Tagging namespace has protected system-group ACEs that Azure DevOps auto-creates and
    # cannot remove. Comparing the full ACL count would always fail, so filter DifferenceACLs.aces
    # to only the identities we are managing.
    if ($ReferenceACLs.Count -gt 0 -and $DifferenceACLs.Count -gt 0) {
        $desiredOriginIds = @($ReferenceACLs[0].aces | ForEach-Object { $_.Identity.value.originId } | Where-Object { $_ })
        if ($desiredOriginIds.Count -gt 0) {
            $DifferenceACLs[0]['aces'] = @($DifferenceACLs[0].aces | Where-Object { $_.Identity.value.originId -in $desiredOriginIds })
        } else {
            $DifferenceACLs[0]['aces'] = @()
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
