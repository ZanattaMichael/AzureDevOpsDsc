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

    $OrgName = Get-AzDoOrganizationName
    $env = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Type 'LivePipelineEnvironments'

    if (-not $env)
    {
        Write-Verbose "[Get-AzDoEnvironmentApproval] Environment '$EnvironmentName' not in cache — falling back to live API lookup."
        $allEnvs = List-DevOpsPipelineEnvironments -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
        $env = $allEnvs | Where-Object { $_.name -eq $EnvironmentName } | Select-Object -First 1
        if ($env) { Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Value $env -Type 'LivePipelineEnvironments' }
    }

    if (-not $env)
    {
        Write-Warning "[Get-AzDoEnvironmentApproval] Environment '$EnvironmentName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    # Look up the approval check from the environment approval cache.
    # If not cached, query the API — LiveEnvironmentApprovals is not populated during Construct().
    $cacheKey = '{0}\{1}' -f $ProjectName, $EnvironmentName
    $approval = Get-CacheItem -Key $cacheKey -Type 'LiveEnvironmentApprovals'

    if (-not $approval)
    {
        Write-Verbose "[GetApproval] Cache miss for '$EnvironmentName' (key=$cacheKey). Querying API with envId=$($env.id)."
        $orgUri = 'https://dev.azure.com/{0}/' -f $OrgName
        $approvalTypeId = '8c6f20a7-a545-4486-9777-f762fafe0d4d'
        try
        {
            $checks = List-DevOpsEnvironmentApprovals -ApiUri $orgUri -ProjectName $ProjectName -EnvironmentId $env.id
            Write-Verbose "[GetApproval] API returned $($checks.Count) checks. Types: $(($checks | ForEach-Object { $_.type.id }) -join ',')"
            $approval = $checks | Where-Object { $_.type.id -eq $approvalTypeId } | Select-Object -First 1
            if ($approval)
            {
                Write-Verbose "[GetApproval] Approval found via API: id=$($approval.id)"
                Add-CacheItem -Key $cacheKey -Value $approval -Type 'LiveEnvironmentApprovals'
            }
        }
        catch
        {
            Write-Warning "[Get-AzDoEnvironmentApproval] Failed to query API for environment approval: $_"
        }
    }
    else
    {
        Write-Verbose "[GetApproval] Approval found in cache: id=$($approval.id) type=$($approval.GetType().Name)"
    }

    if ($approval)
    {
        Write-Verbose "[Get-AzDoEnvironmentApproval] Approval found."
        $result.liveCache   = $approval
        $result.Ensure      = [Ensure]::Present

        # Compare key properties
        $changed = @()
        # Azure DevOps stores these as 'minRequiredApprovers' and 'requesterCannotBeApprover'
        # (the latter is the inverse of "allow approver to approve their own runs").
        $liveCount     = [int]($approval.settings.minRequiredApprovers)
        $liveSelf      = (-not [bool]($approval.settings.requesterCannotBeApprover))
        if ($liveCount -ne [int]$RequiredApproverCount)   { $changed += 'RequiredApproverCount' }
        if ($liveSelf  -ne [bool]$AllowApproverToSelf)    { $changed += 'AllowApproverToSelf' }

        $result.propertiesChanged = $changed
        $result.status = if ($changed.Count -eq 0) { [DSCGetSummaryState]::Unchanged } else { [DSCGetSummaryState]::Changed }
    }
    else
    {
        Write-Verbose "[GetApproval] No approval found for env=$EnvironmentName project=$ProjectName"
        $result.status = [DSCGetSummaryState]::NotFound
    }

    return $result
}
