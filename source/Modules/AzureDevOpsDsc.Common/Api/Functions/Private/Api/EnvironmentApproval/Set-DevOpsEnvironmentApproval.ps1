Function Set-DevOpsEnvironmentApproval
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][Object]$CheckId,
        [Parameter(Mandatory)][Object]$EnvironmentId,
        [Parameter(Mandatory)][string[]]$ApproverIds,
        [Parameter()][int]$RequiredApproverCount = 1,
        [Parameter()][bool]$AllowApproverToApproveOwnRuns = $false,
        [Parameter()][int]$TimeoutInMinutes = 43200,
        [Parameter()][string]$Instructions,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $approvers = $ApproverIds | ForEach-Object { @{ id = $_ } }
    $params = @{
        Uri         = '{0}/{1}/_apis/pipelines/checks/configurations/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $CheckId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = @{
            id       = $CheckId
            type     = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d'; name = 'Approval' }
            settings = @{
                approvers                       = @($approvers)
                requiredApproverCount           = $RequiredApproverCount
                allowApproverToApproveOwnRuns   = $AllowApproverToApproveOwnRuns
                instructions                    = $Instructions
            }
            timeout  = $TimeoutInMinutes
            resource = @{
                type = 'environment'
                id   = $EnvironmentId.ToString()
            }
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsEnvironmentApproval] Failed to update environment approval '$CheckId': $_" }
}
