function Get-DevOpsACL
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName,

        [Parameter(Mandatory = $true)]
        [String]$SecurityDescriptorId,

        # Optional ACL token. When supplied, the API returns only the ACL(s) for this token
        # instead of every ACL in the namespace — far less data to transfer, parse and format.
        [Parameter()]
        [String]$Token,

        # Return inherited/effective ACE info. Only needed for hierarchical namespaces
        # (e.g. Git repo/branch, Area/Iteration) where parent-scope ACEs matter.
        [Parameter()]
        [bool]$IncludeExtendedInfo = $false,

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    # Construct the URL for the API call
    $uri = 'https://dev.azure.com/{0}/_apis/accesscontrollists/{1}?api-version={2}' -f `
        $OrganizationName, $SecurityDescriptorId, $ApiVersion

    # The token must be URL-encoded — it contains '$', ':' and '/'.
    if ($Token)               { $uri += '&token={0}' -f [uri]::EscapeDataString($Token) }
    if ($IncludeExtendedInfo) { $uri += '&includeExtendedInfo=true' }

    # A genuine request failure (auth, bad namespace, 4xx/5xx) throws out of
    # Invoke-AzDevOpsApiRestMethod and is left to propagate — callers must not treat a failed
    # request as "no permissions". Only a successful-but-empty response means "no ACL set".
    $ACLList = Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'Get'

    # HTTP 200 with no ACLs = valid "no ACL for this token" state (e.g. a resource that has
    # never had explicit permissions). Return $null; the caller maps this to NotFound, NOT Error.
    if (($null -eq $ACLList.value) -or ($ACLList.count -eq 0))
    {
        return $null
    }

    # Cache keyed by namespace *and* token so a token-scoped fetch never overwrites a
    # full-namespace cache entry (or another token's entry).
    $cacheKey = if ($Token) { '{0}|{1}' -f $SecurityDescriptorId, $Token } else { $SecurityDescriptorId }
    Add-CacheItem -Key $cacheKey -Value $ACLList.value -Type 'LiveACLList'
    Export-CacheObject -CacheType 'LiveACLList' -Content $Global:AzDoLiveACLList

    return $ACLList.value

}
