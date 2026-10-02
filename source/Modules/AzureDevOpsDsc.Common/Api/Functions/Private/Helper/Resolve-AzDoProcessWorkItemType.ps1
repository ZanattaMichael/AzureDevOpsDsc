<#
.SYNOPSIS
Resolves an inherited process and one of its work item types, with the customization rules applied.

.DESCRIPTION
Every process customization resource needs the same three things before it can do anything: the
process id, confirmation that the process is customizable, and the reference name of the work item
type being changed. This helper does all three so that each resource does not repeat it - and so
that the "system processes are read-only" rule is enforced in exactly one place.

The system processes (Agile, Scrum, Basic, CMMI) cannot be customized. The API's error for
attempting it is not obvious, so this reports the reason instead of letting the call fail.

Work item types are addressed by reference name ('MyProcess.Incident') in the API but written by
display name ('Incident') in a configuration, so the lookup matches on either.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessName
The name of the inherited process.

.PARAMETER WorkItemTypeName
The display name or reference name of the work item type. Omit to resolve the process only.

.OUTPUTS
A hashtable with:
  Process          - the resolved process object (carries the id used in API routes), or $null
  ProcessDetail    - the work/processes view of the process, which reports customizationType
  WorkItemType     - the resolved work item type, or $null
  IsCustomizable   - $false for a system process
  Reason           - why resolution stopped, when it did
  Found            - $true when everything requested resolved

.EXAMPLE
Resolve-AzDoProcessWorkItemType -Organization 'myorg' -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident'
#>
Function Resolve-AzDoProcessWorkItemType
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProcessName,

        [Parameter()]
        [AllowEmptyString()]
        [String]$WorkItemTypeName
    )

    $result = @{
        Process        = $null
        ProcessDetail  = $null
        WorkItemType   = $null
        IsCustomizable = $false
        Reason         = $null
        Found          = $false
    }

    $process = Resolve-DevOpsProcess -ProcessName $ProcessName -OrganizationName $Organization

    if ($null -eq $process)
    {
        $result.Reason = 'ProcessNotFound'
        return $result
    }

    $result.Process = $process

    # The process cache is built from the classic _apis/process/processes endpoint, which does not
    # report customizationType or parentProcessTypeId. Those live on the work/processes view, so
    # the customizability check has to read that rather than trusting the cached object.
    $processDetail = Get-DevOpsProcess -Organization $Organization -ProcessTypeId $process.id

    if ($null -eq $processDetail)
    {
        $result.Reason = 'ProcessDetailLookupFailed'
        return $result
    }

    $result.ProcessDetail = $processDetail

    # A system process has no parent: it is the root of its own family and is read-only. An
    # inherited process always derives from one.
    $isSystem = ($processDetail.customizationType -eq 'system') -or
                ([String]::IsNullOrWhiteSpace($processDetail.parentProcessTypeId)) -or
                ($processDetail.parentProcessTypeId -eq '00000000-0000-0000-0000-000000000000')

    if ($isSystem)
    {
        $result.Reason = 'ProcessNotCustomizable'
        return $result
    }

    $result.IsCustomizable = $true

    if ([String]::IsNullOrWhiteSpace($WorkItemTypeName))
    {
        $result.Found = $true
        return $result
    }

    $workItemTypes = List-DevOpsProcessWorkItemTypes -Organization $Organization -ProcessId $process.id

    if ($null -eq $workItemTypes)
    {
        $result.Reason = 'WorkItemTypeLookupFailed'
        return $result
    }

    # Configurations name the type as it appears in the UI; the API addresses it by reference name.
    $workItemType = $workItemTypes | Where-Object {
        ($_.name -eq $WorkItemTypeName) -or ($_.referenceName -eq $WorkItemTypeName)
    } | Select-Object -First 1

    if ($null -eq $workItemType)
    {
        $result.Reason = 'WorkItemTypeNotFound'
        return $result
    }

    $result.WorkItemType = $workItemType
    $result.Found        = $true

    return $result
}
