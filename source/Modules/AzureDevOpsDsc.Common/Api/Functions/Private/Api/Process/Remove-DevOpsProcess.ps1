<#
.SYNOPSIS
Removes an inherited process from Azure DevOps.

.DESCRIPTION
Deletes an inherited process using the Azure DevOps Work Item Tracking Process REST API
(DELETE _apis/work/processes/{processTypeId}). A process that is in use by a project, or a system
process, cannot be deleted and the API returns an error.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessTypeId
The type id (GUID) of the process to delete.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1-preview.2'.

.EXAMPLE
Remove-DevOpsProcess -Organization 'myorg' -ProcessTypeId '...'
#>
function Remove-DevOpsProcess
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$ProcessTypeId,

        [Parameter()]
        [string]$ApiVersion = '7.1-preview.2'
    )

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes/{1}?api-version={2}' -f $Organization, $ProcessTypeId, $ApiVersion
        Method = 'DELETE'
    }

    if (-not $PSCmdlet.ShouldProcess($ProcessTypeId, 'Delete inherited process'))
    {
        return
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        throw "[Remove-DevOpsProcess] Failed to delete process '$ProcessTypeId' in '$Organization': $_"
    }
}
