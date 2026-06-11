Function New-DevOpsEnvironmentApproval
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][int]$EnvironmentId,
        [Parameter(Mandatory)][string[]]$ApproverIds,
        [Parameter()][int]$RequiredApproverCount = 1,
        [Parameter()][bool]$AllowApproverToApproveOwnRuns = $false,
        [Parameter()][int]$TimeoutInMinutes = 43200,
        [Parameter()][string]$Instructions,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $approvers = $ApproverIds | ForEach-Object { @{ id = $_ } }
    $params = @{
        Uri         = '{0}/{1}/_apis/pipelines/checks/configurations?api-version={2}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            type     = @{ id = '8c6f20a7-a545-4486-9777-f762fafe0d4d'; name = 'Approval' }
            settings = @{
                # Azure DevOps approval-check settings use 'minRequiredApprovers' and
                # 'requesterCannotBeApprover' — NOT 'requiredApproverCount'/'allowApproverToApproveOwnRuns'
                # (those names are silently ignored by the API, so the values never persist).
                approvers                 = @($approvers)
                minRequiredApprovers      = $RequiredApproverCount
                requesterCannotBeApprover = (-not $AllowApproverToApproveOwnRuns)
                instructions              = $Instructions
            }
            timeout  = $TimeoutInMinutes
            resource = @{
                type = 'environment'
                id   = $EnvironmentId.ToString()
            }
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsEnvironmentApproval] Failed to create environment approval: $_" }
}
