<#
.SYNOPSIS
Retrieves the current state of organization-level permissions.

.DESCRIPTION
Compares the desired ACEs against the organization root ACL in the 'Collection' security namespace.
Only the identities named in Permissions are compared; the root carries protected and system ACEs
that are left alone.

The root token is taken from the live ACL rather than assumed. If no root ACL is found the status is
Error, and Set and Remove refuse to write.

.PARAMETER GroupName
The group this configuration block is for (the resource key).

.PARAMETER Permissions
The desired ACEs (Identity + Permission map).

.PARAMETER LookupResult
Supplied by the DSC base class.

.PARAMETER Ensure
Supplied by the DSC base class.

.PARAMETER Force
Supplied by the DSC base class.

.OUTPUTS
System.Collections.Hashtable
#>
Function Get-AzDoOrganizationPermission
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoOrganizationPermission] Started."

    $SecurityNamespace = 'Collection'
    $OrganizationName  = Get-AzDoOrganizationName

    $getResult = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        groupName         = $GroupName
        status            = $null
        reason            = $null
    }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $namespace)
    {
        Write-Error "[Get-AzDoOrganizationPermission] Security namespace '$SecurityNamespace' not found." -ErrorAction Continue
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "Security namespace '$SecurityNamespace' not found."
        return $getResult
    }

    $getResult.namespace = $namespace

    # The namespace holds one ACL per organization, so reading it whole is cheap.
    $DevOpsACLs = @(Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId)
    $rootACL    = $DevOpsACLs | Where-Object { $_.token -match $LocalizedDataAzACLTokenPatten.OrganizationPermission } | Select-Object -First 1

    if (-not $rootACL)
    {
        # Never guess the token: an ACL written to the wrong one would silently do nothing.
        $seen = (@($DevOpsACLs | ForEach-Object { $_.token }) | Where-Object { $_ }) -join "', '"
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "No organization root ACL was found in the '$SecurityNamespace' namespace. Tokens seen: '$seen'."
        return $getResult
    }

    $rootToken = $rootACL.token

    # Wrap in @() so a single ACL is not unrolled to a bare hashtable ([0] indexing downstream).
    $DifferenceACLs = @($rootACL | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName)

    # The root has no parent to inherit from, so its inheritance flag is not configurable: the
    # desired ACL takes the live value, which keeps it out of the comparison and the write.
    $params = @{
        Permissions       = $Permissions
        SecurityNamespace = $SecurityNamespace
        isInherited       = [bool]$rootACL.inheritPermissions
        OrganizationName  = $OrganizationName
        TokenName         = $rootToken
    }

    $ReferenceACLs = @(ConvertTo-ACL @params | Where-Object { $_.token.Type -ne 'OrganizationUnknown' })

    # Compare only the identities this resource manages; the root holds many other ACEs.
    if ($ReferenceACLs.Count -gt 0 -and $DifferenceACLs.Count -gt 0)
    {
        $desiredOriginIds = @($ReferenceACLs[0].aces | ForEach-Object { $_.Identity.value.originId } | Where-Object { $_ })
        if ($desiredOriginIds.Count -gt 0)
        {
            $DifferenceACLs[0]['aces'] = @($DifferenceACLs[0].aces | Where-Object { $_.Identity.value.originId -in $desiredOriginIds })
        }
        else
        {
            $DifferenceACLs[0]['aces'] = @()
        }
    }

    $compareResult = Test-ACLListforChanges -ReferenceACLs $ReferenceACLs -DifferenceACLs $DifferenceACLs

    $getResult.propertiesChanged = $compareResult.propertiesChanged
    $getResult.status            = [DSCGetSummaryState]::"$($compareResult.status)"
    $getResult.reason            = $compareResult.reason

    # Absent means none of the managed identities holds an entry on the token. The base class only
    # treats NotFound as absent, so report that once they are all gone; otherwise Test stays False
    # and Remove runs on every pass.
    # With no identity resolved there is nothing managed to look for, so the live ACEs do not count.
    $managedAceCount = if ($ReferenceACLs.Count -eq 0) { 0 }
                       else { @($DifferenceACLs | ForEach-Object { $_.aces } | Where-Object { $_ }).Count }
    if ($Ensure -eq [Ensure]::Absent -and $managedAceCount -eq 0)
    {
        $getResult.status = [DSCGetSummaryState]::NotFound
        $getResult.reason = 'None of the managed identities has an entry on the organization root.'
    }
    $getResult.ReferenceACLs     = $ReferenceACLs
    $getResult.DifferenceACLs    = $DifferenceACLs
    $getResult.aclToken          = $rootToken
    # The raw ACL, so Set can carry every ACE it does not manage through the replacing POST.
    $getResult.LiveACLs          = @($rootACL)

    return $getResult
}
