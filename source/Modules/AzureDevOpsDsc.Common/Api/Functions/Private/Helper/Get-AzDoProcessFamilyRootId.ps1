<#
.SYNOPSIS
Resolves the "family root" process type id for a process detail object.

.DESCRIPTION
Azure DevOps only allows a project to migrate between processes that belong to the same OOB
(out-of-box) process family: a system process (Agile, Scrum, Basic, CMMI) and its inherited
children, or two inherited children of the same parent. This helper reduces a process detail
object (as returned by Get-DevOpsProcess) down to the id that identifies that family, so two
processes can be compared for migration-compatibility with a single equality check.

A system process has no parent: it is the root of its own family, so its own typeId is returned.
An inherited process always derives from one, so its parentProcessTypeId is returned instead.

.PARAMETER ProcessDetail
The process detail object returned by Get-DevOpsProcess (carries typeId, parentProcessTypeId and
customizationType).

.OUTPUTS
The family root process type id (a GUID string), or $null when ProcessDetail is $null.

.EXAMPLE
Get-AzDoProcessFamilyRootId -ProcessDetail $processDetail
#>
function Get-AzDoProcessFamilyRootId
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [System.Object]$ProcessDetail
    )

    if ($null -eq $ProcessDetail)
    {
        return $null
    }

    $isSystem = ($ProcessDetail.customizationType -eq 'system') -or
                ([String]::IsNullOrWhiteSpace($ProcessDetail.parentProcessTypeId)) -or
                ($ProcessDetail.parentProcessTypeId -eq '00000000-0000-0000-0000-000000000000')

    if ($isSystem)
    {
        return $ProcessDetail.typeId
    }

    return $ProcessDetail.parentProcessTypeId
}
