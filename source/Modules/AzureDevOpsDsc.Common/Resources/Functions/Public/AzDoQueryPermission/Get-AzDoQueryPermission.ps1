<#
.SYNOPSIS
Retrieves the current ACL state of an Azure DevOps work item query folder.

.DESCRIPTION
Builds the 'WorkItemQueryFolders' ACL token for the folder, fetches the matching ACLs and
compares them against the desired permissions.

The token addresses folders by GUID - '$/{projectId}/{folderId}/{subfolderId}' - so the
readable path is resolved to its chain of ids first. Omitting QueryPath targets the project's
query root, whose token is '$/{projectId}'.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER QueryPath
The full path of the query folder. Omit to target the project's query root.

.PARAMETER isInherited
Whether the ACL inherits permissions from its parent.

.PARAMETER Permissions
The desired access control entries.

.PARAMETER LookupResult
The lookup result from a previous call, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoQueryPermission -ProjectName 'Contoso' -QueryPath 'Shared Queries/Platform' -isInherited $true
#>
Function Get-AzDoQueryPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $false)]
        [Alias('Path')]
        [System.String]$QueryPath,

        [Parameter(Mandatory = $true)]
        [System.Boolean]$isInherited,

        [Parameter()]
        [HashTable[]]$Permissions,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoQueryPermission] Started."

    # https://learn.microsoft.com/en-us/azure/devops/organizations/security/namespace-reference
    $SecurityNamespace = 'WorkItemQueryFolders'
    $OrganizationName  = Get-AzDoOrganizationName

    $results = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        project           = $ProjectName
        queryPath         = (Format-AzDoQueryPath -Path $QueryPath)
        status            = $null
        reason            = $null
        identifiers       = $null
    }

    $normalizedPath = $results.queryPath

    if ([String]::IsNullOrWhiteSpace($normalizedPath))
    {
        Write-Verbose "[Get-AzDoQueryPermission] QueryPath not specified. Defaulting to the project's query root."
    }

    #
    # Resolve the project

    $projectCache = Resolve-AzDoProject -ProjectName $ProjectName

    if ($null -eq $projectCache)
    {
        Write-Warning "[Get-AzDoQueryPermission] Project not found: $ProjectName"
        $results.status = [DSCGetSummaryState]::Error
        $results.reason = "Project not found: $ProjectName"
        return $results
    }

    #
    # Resolve the query folder path to its chain of folder ids

    $identifierArr = @()

    if (-not [String]::IsNullOrWhiteSpace($normalizedPath))
    {
        $resolved = Resolve-AzDoQueryPath -Organization $OrganizationName -ProjectName $ProjectName -Path $normalizedPath

        if (-not $resolved.Exists)
        {
            # Name the segment that could not be resolved - "query folder not found" on a deep
            # path is otherwise very hard to act on.
            $failedAt = ($resolved.Segments[0..$resolved.Resolved]) -join '/'
            Write-Warning "[Get-AzDoQueryPermission] Query folder '$normalizedPath' not found in project '$ProjectName'. Path resolution stopped at '$failedAt'."
            $results.status = [DSCGetSummaryState]::NotFound
            $results.reason = "Query folder not found: $normalizedPath"
            return $results
        }

        if ($null -ne $resolved.Item -and (-not $resolved.Item.isFolder))
        {
            Write-Error "[Get-AzDoQueryPermission] '$normalizedPath' in project '$ProjectName' is a query, not a folder. Permissions in the WorkItemQueryFolders namespace are set on folders."
            $results.status = [DSCGetSummaryState]::Error
            $results.reason = 'PathIsNotAFolder'
            return $results
        }

        $identifierArr = @($resolved.IdChain)
    }

    $results.identifiers = $identifierArr

    #
    # Build the ACL token

    $aclToken = '$/{0}' -f $projectCache.id
    if ($identifierArr.Count -gt 0)
    {
        $aclToken += ($identifierArr | ForEach-Object { '/{0}' -f $_ }) -join ''
    }

    Write-Verbose "[Get-AzDoQueryPermission] ACL Token: $aclToken"

    #
    # Perform the lookup of the permissions

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'

    if ($null -eq $namespace)
    {
        Write-Error "[Get-AzDoQueryPermission] Security namespace '$SecurityNamespace' was not found in the cache."
        $results.status = [DSCGetSummaryState]::Error
        $results.reason = "Security namespace not found: $SecurityNamespace"
        return $results
    }

    $results.namespace = $namespace

    # Scope the ACL fetch to this token rather than reading the whole namespace, falling back to
    # the full fetch if the scoped query returns nothing - so behaviour is never worse than an
    # unscoped scan.
    $ACLLookupParams = @{
        OrganizationName     = $OrganizationName
        SecurityDescriptorId = $namespace.namespaceId
        Token                = $aclToken
    }

    $DevOpsACLs = Get-DevOpsACL @ACLLookupParams

    if ($null -eq $DevOpsACLs)
    {
        $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId
    }

    if ($null -eq $DevOpsACLs)
    {
        Write-Error "[Get-AzDoQueryPermission] No ACLs were found within the Security Namespace."
        $results.status = [DSCGetSummaryState]::Error
        $results.reason = "No ACLs were found within the Security Namespace."
        return $results
    }

    # Drop the ACLs this lookup cannot be interested in BEFORE formatting them, exactly as
    # Get-AzDoProjectPermission and Get-AzDoProcessPermission already do. Formatting resolves every
    # ACE through Find-Identity, which costs an API round trip for each descriptor that is not
    # already cached, so formatting a whole namespace only to keep one token is where the time goes.
    # The fallback above fires whenever the query folder has no explicit ACL - the normal state
    # once permissions revert to inherited - so the full namespace is the common path, not a rare
    # one. The folder ids are matched unordered here, a superset of the ordered filter
    # below, which still decides what is kept. With no ids (the project query root) there is nothing
    # to narrow on, so the list is left as it is.
    $DevOpsACLs = @($DevOpsACLs | Where-Object {
        $rawToken = $_.token
        if ([String]::IsNullOrEmpty($rawToken)) { return $false }
        foreach ($identifier in $identifierArr)
        {
            if ($rawToken -notlike ('*{0}*' -f $identifier)) { return $false }
        }
        return $true
    })

    $DifferenceACLs = @($DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName)

    # No ACL for this token is a valid state, not a missing resource - it is what the API returns
    # once permissions revert to inherited. NotFound here would tell the base class Ensure is Absent
    # and skip Set, so the empty list goes to Test-ACLListforChanges instead, which reads "none
    # desired, none present" as Unchanged and "some desired, none present" as Changed.

    # Keep only the ACL for this exact folder. The comparison is order-sensitive: the token is a
    # path, so the same ids in a different order describe a different folder.
    $DifferenceACLs = $DifferenceACLs | Where-Object { $_.Token.Type -eq 'QueryPermission' } | Where-Object {

        if ($_.token.Identifiers.Count -ne $identifierArr.Count) { return $false }

        for ($i = 0; $i -lt $identifierArr.Count; $i++)
        {
            if ($_.token.Identifiers[$i].identifier -ne $identifierArr[$i]) { return $false }
        }

        return $true
    }

    Write-Verbose "[Get-AzDoQueryPermission] ACL List retrieved and formatted."

    #
    # Convert the desired permissions into an ACL and compare

    $params = @{
        Permissions       = $Permissions
        SecurityNamespace = $SecurityNamespace
        isInherited       = $isInherited
        OrganizationName  = $OrganizationName
        TokenName         = $aclToken
    }

    $ReferenceACLs = ConvertTo-ACL @params

    $compareResult = Test-ACLListforChanges -ReferenceACLs $ReferenceACLs -DifferenceACLs $DifferenceACLs

    $results.propertiesChanged = $compareResult.propertiesChanged
    $results.status            = [DSCGetSummaryState]::"$($compareResult.status)"
    $results.reason            = $compareResult.reason
    $results.ReferenceACLs     = $ReferenceACLs
    $results.DifferenceACLs    = $DifferenceACLs
    $results.aclToken          = $aclToken

    Write-Verbose "[Get-AzDoQueryPermission] Result Status: $($results.status)"

    return $results
}
