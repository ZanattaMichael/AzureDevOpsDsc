<#
.SYNOPSIS
Builds the Process security namespace ACL token for a given process scope.

.DESCRIPTION
Returns the ACL token used by the 'Process' security namespace:

  - The sentinel 'AllProcesses' resolves to the org-wide root token '$PROCESS', which governs who can
    create, edit, delete and administer processes across the organization (the scope that grants the
    ability to create inherited/child processes).
  - A specific inherited process name resolves to '$PROCESS:{parentProcessTypeId}:{processTypeId}'.

System processes (Agile, Scrum, CMMI, Basic) have no per-process ACL token; their create/administer
security lives at the root scope, so passing a system process name returns $null with a warning.

.PARAMETER ProcessName
The process name, or the sentinel 'AllProcesses' for the org-wide root scope.

.PARAMETER OrganizationName
The name of the Azure DevOps organization.

.OUTPUTS
The ACL token string, or $null when the scope cannot be resolved to a token.

.EXAMPLE
Get-DevOpsProcessAclToken -ProcessName 'AllProcesses' -OrganizationName 'myorg'   # -> '$PROCESS'

.EXAMPLE
Get-DevOpsProcessAclToken -ProcessName 'Contoso Agile' -OrganizationName 'myorg'  # -> '$PROCESS:{parent}:{id}'
#>
function Get-DevOpsProcessAclToken
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$ProcessName,

        [Parameter(Mandatory = $true)]
        [string]$OrganizationName
    )

    # Org-wide root scope.
    if ($ProcessName -eq 'AllProcesses')
    {
        return '$PROCESS'
    }

    $process = Resolve-DevOpsProcess -ProcessName $ProcessName -OrganizationName $OrganizationName
    if ($null -eq $process)
    {
        Write-Warning "[Get-DevOpsProcessAclToken] Process '$ProcessName' not found; cannot build a Process ACL token."
        return $null
    }

    # The list/cache shape lacks parentProcessTypeId; fetch the full process to obtain it.
    $detail = Get-DevOpsProcess -Organization $OrganizationName -ProcessTypeId $process.id
    $parentProcessTypeId = $detail.parentProcessTypeId

    $emptyGuid = '00000000-0000-0000-0000-000000000000'
    if ([string]::IsNullOrEmpty($parentProcessTypeId) -or $parentProcessTypeId -eq $emptyGuid)
    {
        Write-Warning "[Get-DevOpsProcessAclToken] '$ProcessName' is a system process with no per-process ACL token. Use 'AllProcesses' to manage org-wide process permissions."
        return $null
    }

    return '$PROCESS:{0}:{1}' -f $parentProcessTypeId, $process.id
}
