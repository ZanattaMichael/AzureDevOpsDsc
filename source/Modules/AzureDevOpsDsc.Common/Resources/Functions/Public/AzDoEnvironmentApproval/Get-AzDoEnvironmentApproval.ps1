Function Get-AzDoEnvironmentApproval
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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

    Write-Verbose "[Get-AzDoEnvironmentApproval] Started."

    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }

    $env = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Type 'LivePipelineEnvironments'

    if (-not $env)
    {
        Write-Warning "[Get-AzDoEnvironmentApproval] Environment '$EnvironmentName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    # Look up the approval check from the environment approval cache
    $cacheKey = '{0}\{1}' -f $ProjectName, $EnvironmentName
    $approval = Get-CacheItem -Key $cacheKey -Type 'LiveEnvironmentApprovals'

    if ($approval)
    {
        Write-Verbose "[Get-AzDoEnvironmentApproval] Approval found."
        $result.liveCache = $approval

        # Compare key properties
        $changed = @()
        if ($approval.settings.requiredApproverCount -ne $RequiredApproverCount) { $changed += 'RequiredApproverCount' }
        if ($approval.settings.allowApproverToApproveOwnRuns -ne $AllowApproverToSelf) { $changed += 'AllowApproverToSelf' }

        $result.propertiesChanged = $changed
        $result.status = if ($changed.Count -eq 0) { [DSCGetSummaryState]::Unchanged } else { [DSCGetSummaryState]::Changed }
    }
    else
    {
        $result.status = [DSCGetSummaryState]::NotFound
    }

    return $result
}
