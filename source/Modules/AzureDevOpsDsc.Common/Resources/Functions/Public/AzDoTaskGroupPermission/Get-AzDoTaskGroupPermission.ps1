<#
.SYNOPSIS
Retrieves the current state of task group permissions.

.DESCRIPTION
Compares the desired ACEs against the 'MetaTask' ACL for a task group ('{projectId}/{taskGroupId}'),
or for the project level ('{projectId}') when TaskGroupName is omitted. Only the identities named in
Permissions are compared.

A missing project or task group is NotFound. New refuses to write in that case, since there is no
token to write to.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TaskGroupName
The name of the task group. Omit to target the project level.

.PARAMETER isInherited
Whether the ACL inherits permissions from the project level.

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
Function Get-AzDoTaskGroupPermission
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter()][string]$TaskGroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoTaskGroupPermission] Started."

    $SecurityNamespace = 'MetaTask'
    $OrganizationName  = Get-AzDoOrganizationName

    $getResult = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        project           = $ProjectName
        taskGroupName     = $TaskGroupName
        status            = $null
        reason            = $null
    }

    # Resolve-AzDoProject returns $null on a 404 (a deleted project) and rethrows anything else.
    $project = Resolve-AzDoProject -ProjectName $ProjectName
    if (-not $project)
    {
        $getResult.status = [DSCGetSummaryState]::NotFound
        $getResult.reason = "Project not found: $ProjectName"
        return $getResult
    }

    $taskGroup = $null
    if (-not [String]::IsNullOrWhiteSpace($TaskGroupName))
    {
        $cacheKey  = '{0}\{1}' -f $ProjectName, $TaskGroupName
        $taskGroup = Get-CacheItem -Key $cacheKey -Type 'LiveTaskGroups'

        if (-not $taskGroup)
        {
            # The task group cache is only filled by AzDoTaskGroup's own New and Set.
            Write-Verbose "[Get-AzDoTaskGroupPermission] Task group '$TaskGroupName' not in cache - falling back to a live API lookup."
            $apiUri    = 'https://dev.azure.com/{0}/' -f $OrganizationName
            $taskGroup = List-DevOpsTaskGroups -ApiUri $apiUri -ProjectName $ProjectName |
                Where-Object { $_.name -eq $TaskGroupName } | Select-Object -First 1
            if ($taskGroup) { Add-CacheItem -Key $cacheKey -Value $taskGroup -Type 'LiveTaskGroups' }
        }

        if (-not $taskGroup)
        {
            $getResult.status = [DSCGetSummaryState]::NotFound
            $getResult.reason = "Task group not found: $TaskGroupName"
            return $getResult
        }
    }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $namespace)
    {
        Write-Error "[Get-AzDoTaskGroupPermission] Security namespace '$SecurityNamespace' not found." -ErrorAction Continue
        $getResult.status = [DSCGetSummaryState]::Error
        $getResult.reason = "Security namespace '$SecurityNamespace' not found."
        return $getResult
    }

    $getResult.namespace = $namespace

    $aclToken = if ($taskGroup) { '{0}/{1}' -f $project.id, $taskGroup.id }
                else            { '{0}' -f $project.id }

    # A token with no explicit ACL yet comes back empty, which is not an error.
    $DevOpsACLs = @(Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId -Token $aclToken |
        Where-Object { $_.token -eq $aclToken })

    $DifferenceACLs = @($DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName)

    $params = @{
        Permissions       = $Permissions
        SecurityNamespace = $SecurityNamespace
        isInherited       = $isInherited
        OrganizationName  = $OrganizationName
        TokenName         = $aclToken
    }

    $ReferenceACLs = @(ConvertTo-ACL @params | Where-Object { $_.token.Type -ne 'TaskGroupUnknown' })

    # Compare only the identities this resource manages; a task group's creator holds an ACE too.
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
        $getResult.reason = 'None of the managed identities has an entry on the token.'
    }
    $getResult.ReferenceACLs     = $ReferenceACLs
    $getResult.DifferenceACLs    = $DifferenceACLs
    $getResult.aclToken          = $aclToken
    # The raw ACL, so Set can carry every ACE it does not manage through the replacing POST.
    $getResult.LiveACLs          = $DevOpsACLs

    return $getResult
}
