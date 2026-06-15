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

    $OrgName  = Get-AzDoOrganizationName
    $cacheKey = '{0}\{1}' -f $ProjectName, $EnvironmentName
    $env      = Get-CacheItem -Key $cacheKey -Type 'LivePipelineEnvironments'
    $approval = Get-CacheItem -Key $cacheKey -Type 'LiveEnvironmentApprovals'

    if (-not $env)
    {
        Write-Verbose "[Set-AzDoEnvironmentApproval] Environment '$EnvironmentName' not in cache — falling back to live API lookup."
        $allEnvs = List-DevOpsPipelineEnvironments -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
        $env = $allEnvs | Where-Object { $_.name -eq $EnvironmentName } | Select-Object -First 1
        if ($env) { Add-CacheItem -Key $cacheKey -Value $env -Type 'LivePipelineEnvironments' }
    }

    if (-not $approval)
    {
        Write-Verbose "[Set-AzDoEnvironmentApproval] Approval not in cache — querying API."
        $approvalTypeId = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
        $checks = List-DevOpsEnvironmentApprovals -ApiUri "https://dev.azure.com/$OrgName/" -ProjectName $ProjectName -EnvironmentId $env.id
        $approval = $checks | Where-Object { $_.type.id -eq $approvalTypeId } | Select-Object -First 1
        if ($approval) { Add-CacheItem -Key $cacheKey -Value $approval -Type 'LiveEnvironmentApprovals' }
    }

    if ((-not $env) -or (-not $approval))
    {
        Write-Error "[Set-AzDoEnvironmentApproval] Environment or existing approval not found."
        return
    }

    $approverIds = @()
    foreach ($approver in $Approvers)
    {
        $resolved = Find-AzDoIdentity -Identity $approver
        if ($resolved) { $approverIds += $resolved.originId }
        else            { $approverIds += $approver }
    }

    $params = @{
        ApiUri                        = 'https://dev.azure.com/{0}/' -f $OrgName
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
    Write-Verbose "[SetApproval] Set-DevOpsEnvironmentApproval returned: $(if ($null -eq $value) { 'NULL' } else { $value.GetType().Name + ' id=' + $value.id })"

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoEnvironmentApproval] Set-DevOpsEnvironmentApproval returned null. Check authentication token and organization settings."
        return
    }

    $cacheKey = '{0}\{1}' -f $ProjectName, $EnvironmentName
    Add-CacheItem -Key $cacheKey -Value $value -Type 'LiveEnvironmentApprovals'
    $currentCache = Get-CacheObject -CacheType 'LiveEnvironmentApprovals'
    Write-Verbose "[SetApproval] Cache count after Add-CacheItem: $($currentCache.Count)"
    Export-CacheObject -CacheType 'LiveEnvironmentApprovals' -Content $currentCache
}
