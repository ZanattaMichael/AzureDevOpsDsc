Function List-DevOpsTaskGroups
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri    = '{0}/{1}/_apis/distributedtask/taskgroups?api-version={2}' -f $ApiUri, $ProjectName, $ApiVersion
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsTaskGroups] Failed to list task groups for '$ProjectName': $_" }
}
