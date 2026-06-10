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
    # Map caller-friendly flat task hashtables to the Azure DevOps API shape:
    # { task: { id, versionSpec, definitionType }, displayName, enabled, inputs, ... }
    $apiTasks = $Tasks | ForEach-Object {
        $t = $_
        $taskDef = @{
            id             = if ($t.taskId)   { $t.taskId }   elseif ($t.id)   { $t.id }   else { $t.task.id }
            versionSpec    = if ($t.version)  { $t.version }  elseif ($t.versionSpec) { $t.versionSpec } else { $t.task.versionSpec }
            definitionType = if ($t.definitionType) { $t.definitionType } else { 'task' }
        }
        $entry = @{
            task        = $taskDef
            displayName = if ($t.displayName) { $t.displayName } else { $t.name }
            enabled     = if ($null -ne $t.enabled)  { $t.enabled }  else { $true }
            inputs      = if ($t.inputs) { $t.inputs } else { @{} }
        }
        # Pass through any other keys the caller supplied
        foreach ($key in $t.Keys)
        {
            if ($key -notin @('taskId','id','version','versionSpec','definitionType','displayName','name','enabled','inputs'))
            {
                $entry[$key] = $t[$key]
            }
        }
        $entry
    }

    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/taskgroups?api-version={2}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            name        = $TaskGroupName
            description = $Description
            category    = $Category
            tasks       = @($apiTasks)
            inputs      = $Inputs
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsTaskGroup] Failed to create task group '$TaskGroupName': $_" }
}
