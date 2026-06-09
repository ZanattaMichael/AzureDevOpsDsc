Function Set-DevOpsTaskGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$TaskGroupId,
        [Parameter(Mandatory)][string]$TaskGroupName,
        [Parameter()][string]$Description,
        [Parameter()][string]$Category = 'Deploy',
        [Parameter()][hashtable[]]$Tasks = @(),
        [Parameter()][hashtable[]]$Inputs = @(),
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/taskgroups/{2}?api-version={3}' -f $ApiUri, $ProjectName, $TaskGroupId, $ApiVersion
        Method      = 'PUT'
        ContentType = 'application/json'
        Body        = @{
            id          = $TaskGroupId
            name        = $TaskGroupName
            description = $Description
            category    = $Category
            tasks       = $Tasks
            inputs      = $Inputs
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsTaskGroup] Failed to update task group '$TaskGroupId': $_" }
}
