<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps deployment group target.

.DESCRIPTION
Resolves the parent deployment group, then looks up the target by machine name. A target only
exists once an agent has registered itself into the deployment group - this module never
registers one.

When Ensure is Present and no agent is registered under MachineName, this returns
status = Error with reason = 'AgentNotRegistered' so Set-AzDoDeploymentGroupTarget can throw a
clear "install the agent first" error (an Error status is still routed to Set by the base class).

When Ensure is Absent and no agent is registered under MachineName, that already is the desired
state: this returns Ensure = Absent with status = Unchanged, so Test() reports true and nothing
is called.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER DeploymentGroupName
The name of the deployment group the target belongs to.

.PARAMETER MachineName
The name of the machine as registered by the agent.

.PARAMETER Tags
Tags applied to the target. Compared case-insensitively as a set, only when specified.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoDeploymentGroupTarget -ProjectName 'Contoso' -DeploymentGroupName 'Production' -MachineName 'prod-vm-01'
#>
Function Get-AzDoDeploymentGroupTarget
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$DeploymentGroupName,

        [Parameter(Mandatory = $true)]
        [System.String]$MachineName,

        [Parameter()]
        [System.String[]]$Tags,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoDeploymentGroupTarget] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    $organization = Get-AzDoOrganizationName

    $dgCacheKey       = '{0}\{1}' -f $ProjectName, $DeploymentGroupName
    $deploymentGroup = Get-CacheItem -Key $dgCacheKey -Type 'LiveDeploymentGroups'
    if (-not $deploymentGroup)
    {
        $allGroups       = List-DevOpsDeploymentGroups -ApiUri "https://dev.azure.com/$organization" -ProjectName $ProjectName
        $deploymentGroup = $allGroups | Where-Object { $_.name -eq $DeploymentGroupName } | Select-Object -First 1
        if ($deploymentGroup) { Add-CacheItem -Key $dgCacheKey -Value $deploymentGroup -Type 'LiveDeploymentGroups' }
    }

    if ($null -eq $deploymentGroup)
    {
        Write-Verbose "[Get-AzDoDeploymentGroupTarget] Deployment group '$DeploymentGroupName' was not found in project '$ProjectName'."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'DeploymentGroupNotFound'
        return $result
    }

    $result.deploymentGroupId = $deploymentGroup.id

    $targets = List-DevOpsDeploymentGroupTargets -Organization $organization -ProjectName $ProjectName -DeploymentGroupId $deploymentGroup.id
    $target  = $targets | Where-Object { $_.agent.name -eq $MachineName } | Select-Object -First 1

    if ($null -eq $target)
    {
        if ($Ensure -eq [Ensure]::Absent)
        {
            Write-Verbose "[Get-AzDoDeploymentGroupTarget] No agent registered as '$MachineName'. This is already the desired (Absent) state."
            $result.status = [DSCGetSummaryState]::Unchanged
            return $result
        }

        Write-Verbose "[Get-AzDoDeploymentGroupTarget] No agent registered as '$MachineName' in deployment group '$DeploymentGroupName'. Registration is agent-install-only; DSC cannot create this target."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'AgentNotRegistered'
        return $result
    }

    $result.liveCache = $target
    $result.Ensure    = [Ensure]::Present

    $propertiesChanged = @()

    # Tags are compared case-insensitively as a set, and only when the configuration specifies
    # Tags at all - an unset Tags property never reads as "must be empty".
    if ($PSBoundParameters.ContainsKey('Tags'))
    {
        $currentTags = @($target.tags) | Where-Object { $_ }
        $desiredTags = @($Tags) | Where-Object { $_ }
        $currentSet  = [System.Collections.Generic.HashSet[string]]::new([string[]]@($currentTags | ForEach-Object { $_.ToLowerInvariant() }))
        $desiredSet  = [System.Collections.Generic.HashSet[string]]::new([string[]]@($desiredTags | ForEach-Object { $_.ToLowerInvariant() }))
        if (-not $currentSet.SetEquals($desiredSet))
        {
            $propertiesChanged += 'Tags'
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoDeploymentGroupTarget] Target '$MachineName' status: $($result.status)."

    return $result
}
