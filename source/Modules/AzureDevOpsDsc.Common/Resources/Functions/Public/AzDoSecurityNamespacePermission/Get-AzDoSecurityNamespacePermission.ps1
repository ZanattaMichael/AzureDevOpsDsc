Function Get-AzDoSecurityNamespacePermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$SecurityNamespace,
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoSecurityNamespacePermission] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    $getResult = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null; reason = $null }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $namespace)
    {
        Write-Error "[Get-AzDoSecurityNamespacePermission] Security namespace not found."
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "Security namespace '$SecurityNamespace' not found."
        return $getResult
    }

    $getResult.namespace = $namespace

    # New-ACLToken (called by ConvertTo-FormattedACL) strips [ ] from token names.
    # Strip brackets here so the filter matches: "$/[PROJECT]" → "$/PROJECT".
    $strippedToken  = $Token.Replace('[', '').Replace(']', '')

    # Get-DevOpsACL's -Token must be the API's own wire-format token string (e.g. the bare project
    # GUID for 'Build'), NOT the human-readable name in $strippedToken - build it the same way the Set
    # path does, via New-ACLToken + ConvertTo-FormattedToken.
    $queryToken = ConvertTo-FormattedToken -Token (New-ACLToken -SecurityNamespace $SecurityNamespace -TokenName $Token)

    # Token-scope the ACL fetch instead of pulling every ACL in the namespace: for a namespace with
    # a large accumulated ACL list (e.g. Build, shared org-wide), an unscoped fetch has to transfer,
    # parse and Find-Identity-resolve every ACE of every other token too - confirmed via a live wire
    # capture to take several minutes even though this token's own data is tiny.
    #
    # Deliberately NOT falling back to a full-namespace fetch when the scoped query returns $null:
    # Get-DevOpsACL documents $null as a valid "no explicit ACL for this token" answer, not a failure -
    # the most common case is exactly this (creating the first-ever ACE for a token), and falling back
    # to the full scan on $null defeats the whole point of token-scoping for precisely that case.
    $DevOpsACLs = if ($queryToken) { Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId -Token $queryToken }
                  else             { Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId }
    # Wrap in @() so $DifferenceACLs is always an array; ConvertTo-FormattedACL returns a
    # generic List that PowerShell unrolls to a bare hashtable when there is only one entry,
    # making [0] indexing in Test-ACLListforChanges return $null.
    # Use the actual $SecurityNamespace so Format-ACEs and Parse-ACLToken can resolve permission
    # bits against the real namespace descriptor.
    #
    # Filter on $_.ACL.token (the RAW wire-format token string ConvertTo-FormattedACL preserves
    # alongside its parsed form), not $_.Token.TokenValue: Parse-ACLToken only populates .TokenValue
    # for its Generic/unrecognised-namespace fallback - for every explicitly-handled type (Build,
    # Library, ServiceEndpoints, AgentPool, DistributedTask, etc.) .TokenValue is always $null, so this
    # filter always matched nothing for those namespaces. Confirmed live: the Set POST succeeded and the
    # subsequent unfiltered Get-DevOpsACL response DID contain the new ACE, but this filter discarded it
    # every time. $queryToken is already in the same raw wire format, so it compares directly.
    $DifferenceACLs = @($DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName |
        Where-Object { $_.ACL.token -eq $queryToken })

    $params = @{
        Permissions       = $Permissions
        SecurityNamespace = $SecurityNamespace  # use actual namespace so ConvertTo-ACETokenList can resolve permission bits
        isInherited       = $isInherited
        OrganizationName  = $OrganizationName
        TokenName         = $Token
    }

    # Wrap in @() so $ReferenceACLs is always an array; Test-ACLListforChanges uses [0] indexing
    # and a raw hashtable returns $null at index 0.
    $ReferenceACLs = @(ConvertTo-ACL @params)

    $compareResult = Test-ACLListforChanges -ReferenceACLs $ReferenceACLs -DifferenceACLs $DifferenceACLs
    $getResult.propertiesChanged = $compareResult.propertiesChanged
    $getResult.status = [DSCGetSummaryState]::"$($compareResult.status)"
    $getResult.reason = $compareResult.reason
    $getResult.ReferenceACLs  = $ReferenceACLs
    $getResult.DifferenceACLs = $DifferenceACLs

    return $getResult
}
