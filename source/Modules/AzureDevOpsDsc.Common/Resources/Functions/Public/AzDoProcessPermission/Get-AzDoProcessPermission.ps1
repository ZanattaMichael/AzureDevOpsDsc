<#
.SYNOPSIS
Retrieves the current state of Azure DevOps Process permissions.

.DESCRIPTION
Compares the desired Process namespace ACEs against the live ACL for a process scope. The scope is the
org-wide root ('$PROCESS', via ProcessName 'AllProcesses') which governs who can create/edit/delete and
administer processes — including creating inherited (child) processes — or a specific inherited process
('$PROCESS:{parentProcessTypeId}:{processTypeId}').

.PARAMETER ProcessName
The process name, or the sentinel 'AllProcesses' for the org-wide root scope.

.PARAMETER Permissions
An array of hashtables describing the desired ACEs (Identity + Permission map, e.g. @{ Create = 'Allow' }).

.PARAMETER isInherited
Whether the ACL inherits permissions.

.PARAMETER LookupResult
A hashtable to store the lookup result.

.PARAMETER Ensure
Specifies the desired state.

.PARAMETER Force
Forces the operation.

.OUTPUTS
System.Collections.Hashtable
#>
function Get-AzDoProcessPermission
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$ProcessName,

        [Parameter()]
        [HashTable[]]$Permissions,

        [Parameter()]
        [bool]$isInherited = $true,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoProcessPermission] Started."

    $SecurityNamespace = 'Process'
    $OrganizationName  = (Get-AzDoOrganizationName)

    $getResult = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        processName       = $ProcessName
        status            = $null
        reason            = $null
    }

    # Resolve the ACL token for this scope ($PROCESS root, or $PROCESS:{parent}:{id}).
    $processToken = Get-DevOpsProcessAclToken -ProcessName $ProcessName -OrganizationName $OrganizationName
    if (-not $processToken)
    {
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "Could not resolve a Process ACL token for '$ProcessName'."
        return $getResult
    }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $namespace)
    {
        Write-Error "[Get-AzDoProcessPermission] Security namespace '$SecurityNamespace' not found."
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "Security namespace '$SecurityNamespace' not found."
        return $getResult
    }

    $getResult.namespace = $namespace

    $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId
    if (-not $DevOpsACLs)
    {
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = 'No ACLs found.'
        return $getResult
    }

    # Filter the raw ACLs to just this scope's token BEFORE the expensive identity formatting.
    $DevOpsACLs = $DevOpsACLs | Where-Object { $_.token -eq $processToken }

    # Wrap in @() so single results are not unrolled to a bare hashtable (breaks [0] indexing downstream).
    $DifferenceACLs = @($DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName)

    $params = @{
        Permissions       = $Permissions
        SecurityNamespace = $SecurityNamespace
        isInherited       = $isInherited
        OrganizationName  = $OrganizationName
        TokenName         = $processToken
    }

    $ReferenceACLs = @(ConvertTo-ACL @params | Where-Object { $_.token.Type -ne 'ProcessUnknown' })

    # The Process namespace has protected system-group ACEs that cannot be removed. Filter the live ACEs
    # down to just the identities we manage so the comparison only considers the relevant ACE(s).
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
    $getResult.ReferenceACLs     = $ReferenceACLs
    $getResult.DifferenceACLs    = $DifferenceACLs

    return $getResult
}
