<#
.SYNOPSIS
Edits an existing inherited process in Azure DevOps.

.DESCRIPTION
Updates the name and/or description of an inherited process using the Azure DevOps Work Item Tracking
Process REST API (PATCH _apis/work/processes/{processTypeId}). System processes cannot be edited.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessTypeId
The type id (GUID) of the process to edit.

.PARAMETER Name
The new name for the process.

.PARAMETER Description
The new description for the process.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1-preview.2'.

.EXAMPLE
Update-DevOpsProcess -Organization 'myorg' -ProcessTypeId '...' -Name 'MyAgile' -Description 'Updated'
#>
function Update-DevOpsProcess
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$ProcessTypeId,

        [Parameter()]
        [string]$Name,

        [Parameter()]
        [string]$Description,

        [Parameter()]
        [string]$ApiVersion = '7.1-preview.2'
    )

    # Only send the fields that were supplied so we never blank out a value we were not asked to change.
    $body = @{}
    if ($PSBoundParameters.ContainsKey('Name'))        { $body.name        = $Name }
    if ($PSBoundParameters.ContainsKey('Description')) { $body.description = $Description }

    if ($body.Keys.Count -eq 0)
    {
        Write-Verbose '[Update-DevOpsProcess] No updatable fields supplied; nothing to do.'
        return
    }

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}?api-version={2}' -f $Organization, $ProcessTypeId, $ApiVersion
        Method = 'PATCH'
        Body   = $body | ConvertTo-Json
    }

    if (-not $PSCmdlet.ShouldProcess($ProcessTypeId, 'Edit inherited process'))
    {
        return
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        throw "[Update-DevOpsProcess] Failed to edit process '$ProcessTypeId' in '$Organization': $_"
    }
}
