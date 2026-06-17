Function New-AzDoEnvironmentApproval
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

    Write-Verbose "[New-AzDoEnvironmentApproval] Creating approval for '$EnvironmentName'."

    $OrgName = Get-AzDoOrganizationName
    $env = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Type 'LivePipelineEnvironments'

    if (-not $env)
    {
        Write-Verbose "[New-AzDoEnvironmentApproval] Environment '$EnvironmentName' not in cache — falling back to live API lookup."
        $allEnvs = List-DevOpsPipelineEnvironments -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
        $env = $allEnvs | Where-Object { $_.name -eq $EnvironmentName } | Select-Object -First 1
        if ($env) { Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Value $env -Type 'LivePipelineEnvironments' }
    }

    if (-not $env) { Write-Error "[New-AzDoEnvironmentApproval] Environment not found."; return }

    # Resolve approver IDs from group/user cache, with live fallback for cache misses.
    # Approver strings are expected in [ProjectName]\GroupName or UPN format (the PrincipalName used as cache key).
    $approverIds = @()
    foreach ($approver in $Approvers)
    {
        $resolved = Find-AzDoIdentity -Identity $approver
        if ($resolved) { $approverIds += $resolved.originId }
        else            { $approverIds += $approver }
    }

    $params = @{
        ApiUri                      = 'https://dev.azure.com/{0}/' -f $OrgName
        ProjectName                 = $ProjectName
        EnvironmentId               = $env.id
        ApproverIds                 = $approverIds
        RequiredApproverCount       = $RequiredApproverCount
        AllowApproverToApproveOwnRuns = $AllowApproverToSelf
        TimeoutInMinutes            = $TimeoutInMinutes
        Instructions                = $Instructions
    }

    $value = New-DevOpsEnvironmentApproval @params
    Write-Verbose "[NewApproval] New-DevOpsEnvironmentApproval returned: $(if ($null -eq $value) { 'NULL' } else { $value.GetType().Name + ' id=' + $value.id })"

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoEnvironmentApproval] New-DevOpsEnvironmentApproval returned null. Check authentication token and organization settings."
        return
    }

    $cacheKey = '{0}\{1}' -f $ProjectName, $EnvironmentName
    Add-CacheItem -Key $cacheKey -Value $value -Type 'LiveEnvironmentApprovals'
    $currentCache = Get-CacheObject -CacheType 'LiveEnvironmentApprovals'
    Write-Verbose "[NewApproval] Cache count after Add-CacheItem: $($currentCache.Count)"
    Export-CacheObject -CacheType 'LiveEnvironmentApprovals' -Content $currentCache
    Write-Verbose "[New-AzDoEnvironmentApproval] Approval created."
}
