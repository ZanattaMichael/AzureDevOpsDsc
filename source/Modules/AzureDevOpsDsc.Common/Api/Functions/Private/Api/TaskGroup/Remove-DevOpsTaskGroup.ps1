Function Remove-DevOpsTaskGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$TaskGroupId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri    = '{0}/{1}/_apis/distributedtask/taskgroups/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $TaskGroupId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsTaskGroup] Failed to remove task group '$TaskGroupId': $_" }
}
