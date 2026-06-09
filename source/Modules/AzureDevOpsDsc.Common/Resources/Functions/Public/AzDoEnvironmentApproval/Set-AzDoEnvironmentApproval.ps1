Function Set-AzDoEnvironmentApproval
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$EnvironmentName,
        [Parameter(Mandatory = $true)][string[]]$Approvers,
        [Parameter()][uint32]$RequiredApproverCount = 1,
        [Parameter()][bool]$AllowApproverToSelf = $false,
        [Parameter()][uint32]$TimeoutInMinutes = 43200,
        [Parameter()][string]$Instructions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoEnvironmentApproval] Updating approval for '$EnvironmentName'."

    $env      = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Type 'LivePipelineEnvironments'
    $approval = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Type 'LiveEnvironmentApprovals'

    if ((-not $env) -or (-not $approval))
    {
        Write-Error "[Set-AzDoEnvironmentApproval] Environment or existing approval not found."
        return
    }

    $approverIds = @()
    foreach ($approver in $Approvers)
    {
        $resolved = Get-CacheItem -Key ('[{0}]\{1}' -f $ProjectName, $approver) -Type 'LiveGroups'
        if (-not $resolved) { $resolved = Get-CacheItem -Key $approver -Type 'LiveUsers' }
        if ($resolved) { $approverIds += $resolved.originId }
        else            { $approverIds += $approver }
    }

    $params = @{
        ApiUri                        = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName                   = $ProjectName
        CheckId                       = $approval.id
        EnvironmentId                 = $env.id
        ApproverIds                   = $approverIds
        RequiredApproverCount         = $RequiredApproverCount
        AllowApproverToApproveOwnRuns = $AllowApproverToSelf
        TimeoutInMinutes              = $TimeoutInMinutes
        Instructions                  = $Instructions
    }

    $value = Set-DevOpsEnvironmentApproval @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoEnvironmentApproval] Set-DevOpsEnvironmentApproval returned null. Check authentication token and organization settings."
        return
    }

    $cacheKey = '{0}\{1}' -f $ProjectName, $EnvironmentName
    Add-CacheItem -Key $cacheKey -Value $value -Type 'LiveEnvironmentApprovals'
    Export-CacheObject -CacheType 'LiveEnvironmentApprovals' -Content $AzDoLiveEnvironmentApprovals
}
