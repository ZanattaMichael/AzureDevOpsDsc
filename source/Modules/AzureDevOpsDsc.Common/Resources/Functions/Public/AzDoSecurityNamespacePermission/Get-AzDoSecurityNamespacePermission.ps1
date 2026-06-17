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

    $DevOpsACLs     = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId
    # New-ACLToken (called by ConvertTo-FormattedACL) strips [ ] from token names.
    # Strip brackets here so the filter matches: "$/[PROJECT]" → "$/PROJECT".
    $strippedToken  = $Token.Replace('[', '').Replace(']', '')
    # Wrap in @() so $DifferenceACLs is always an array; ConvertTo-FormattedACL returns a
    # generic List that PowerShell unrolls to a bare hashtable when there is only one entry,
    # making [0] indexing in Test-ACLListforChanges return $null.
    # Use the actual $SecurityNamespace so Format-ACEs and Parse-ACLToken can resolve permission
    # bits against the real namespace descriptor. Both functions fall through to a Generic passthrough
    # for namespaces not explicitly handled, preserving the raw token string with brackets intact.
    $DifferenceACLs = @($DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName |
        Where-Object { $_.Token.TokenValue -eq $strippedToken })

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
