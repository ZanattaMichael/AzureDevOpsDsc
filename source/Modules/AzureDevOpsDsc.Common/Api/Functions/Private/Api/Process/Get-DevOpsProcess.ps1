<#
.SYNOPSIS
Gets a single Azure DevOps process, including its parent process type id.

.DESCRIPTION
Retrieves a process by its type id using the Work Item Tracking Process REST API
(GET _apis/work/processes/{processTypeId}). Unlike the older _apis/process/processes list (used to seed
the cache), this endpoint returns parentProcessTypeId, which is required to build a process ACL token
of the form $PROCESS:{parentProcessTypeId}:{processTypeId}.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessTypeId
The type id (GUID) of the process to retrieve.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1-preview.2'.

.OUTPUTS
The process object (typeId, name, description, parentProcessTypeId, customizationType), or $null.

.EXAMPLE
Get-DevOpsProcess -Organization 'myorg' -ProcessTypeId '73295818-1008-4d75-87f8-2192975c71cf'
#>
function Get-DevOpsProcess
{
    [CmdletBinding()]
    [OutputType([System.Object])]
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
        Method = 'Get'
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        Write-Verbose "[Get-DevOpsProcess] Lookup of process '$ProcessTypeId' failed: $_"
        return $null
    }
}
