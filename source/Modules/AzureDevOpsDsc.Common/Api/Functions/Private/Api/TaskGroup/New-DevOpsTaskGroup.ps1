Function New-DevOpsTaskGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$TaskGroupName,
        [Parameter()][string]$Description,
        [Parameter()][string]$Category = 'Deploy',
        [Parameter()][hashtable[]]$Tasks = @(),
        [Parameter()][hashtable[]]$Inputs = @(),
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/taskgroups?api-version={2}' -f $ApiUri, $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            name        = $TaskGroupName
            description = $Description
            category    = $Category
            tasks       = $Tasks
            inputs      = $Inputs
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsTaskGroup] Failed to create task group '$TaskGroupName': $_" }
}
