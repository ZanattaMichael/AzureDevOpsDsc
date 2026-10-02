<#
.SYNOPSIS
Migrates an Azure DevOps project to a different process.

.DESCRIPTION
Calls the Work Item Tracking process migration endpoint (POST
_apis/wit/projectprocessmigration) to move a project onto a different process. This call is
synchronous - Azure DevOps only allows migrating within the same OOB (out-of-box) process family,
for example between a system process and one of its inherited children, or between two inherited
children of the same parent. Migrating across unrelated families is rejected by the API, so the
caller is expected to have already confirmed compatibility (see Get-AzDoProcessFamilyRootId)
before calling this.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectId
The id of the project to migrate.

.PARAMETER ProcessTypeId
The type id (GUID) of the process to migrate the project to.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.OUTPUTS
The ProcessMigrationResultModel returned by the API (processId, projectId).

.EXAMPLE
Move-DevOpsProjectProcess -Organization 'myorg' -ProjectId '11111111-1111-1111-1111-111111111111' -ProcessTypeId '22222222-2222-2222-2222-222222222222'
#>
function Move-DevOpsProjectProcess
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$ProjectId,

        [Parameter(Mandatory = $true)]
        [string]$ProcessTypeId,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    Write-Verbose "[Move-DevOpsProjectProcess] Migrating project '$ProjectId' to process '$ProcessTypeId' in organization '$Organization'"

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/wit/projectprocessmigration?api-version={2}' -f $Organization, $ProjectId, $ApiVersion
        Method = 'Post'
        Body   = @{ typeId = $ProcessTypeId } | ConvertTo-Json
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        throw "[Move-DevOpsProjectProcess] Failed to migrate project '$ProjectId' to process '$ProcessTypeId' in '$Organization': $_"
    }
}
