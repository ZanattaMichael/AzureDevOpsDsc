<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps environment virtual machine resource.

.DESCRIPTION
Resolves the parent pipeline environment, then looks up the VM resource by machine name. A VM
resource only exists once an agent has registered itself against the environment - this module
never registers one.

When Ensure is Present and no agent is registered under MachineName, this returns
status = Error with reason = 'AgentNotRegistered' so Set-AzDoEnvironmentVMResource can throw a
clear "install the agent first" error (an Error status is still routed to Set by the base class).

When Ensure is Absent and no agent is registered under MachineName, that already is the desired
state: this returns Ensure = Absent with status = Unchanged, so Test() reports true and nothing
is called.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER EnvironmentName
The name of the pipeline environment the resource belongs to.

.PARAMETER MachineName
The name of the machine as registered by the agent.

.PARAMETER Tags
Tags applied to the resource. Compared case-insensitively as a set, only when specified.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoEnvironmentVMResource -ProjectName 'Contoso' -EnvironmentName 'Production' -MachineName 'prod-vm-01'
#>
Function Get-AzDoEnvironmentVMResource
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$EnvironmentName,

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

    Write-Verbose "[Get-AzDoEnvironmentVMResource] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    $organization = Get-AzDoOrganizationName

    $envCacheKey = '{0}\{1}' -f $ProjectName, $EnvironmentName
    $environment = Get-CacheItem -Key $envCacheKey -Type 'LivePipelineEnvironments'
    if (-not $environment)
    {
        $allEnvironments = List-DevOpsPipelineEnvironments -ApiUri "https://dev.azure.com/$organization" -ProjectName $ProjectName
        $environment     = $allEnvironments | Where-Object { $_.name -eq $EnvironmentName } | Select-Object -First 1
        if ($environment) { Add-CacheItem -Key $envCacheKey -Value $environment -Type 'LivePipelineEnvironments' }
    }

    if ($null -eq $environment)
    {
        Write-Verbose "[Get-AzDoEnvironmentVMResource] Environment '$EnvironmentName' was not found in project '$ProjectName'."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'EnvironmentNotFound'
        return $result
    }

    $result.environmentId = $environment.id

    $resources = List-DevOpsEnvironmentVMResources -Organization $organization -ProjectName $ProjectName -EnvironmentId $environment.id
    $resource  = $resources | Where-Object { $_.name -eq $MachineName } | Select-Object -First 1

    if ($null -eq $resource)
    {
        if ($Ensure -eq [Ensure]::Absent)
        {
            Write-Verbose "[Get-AzDoEnvironmentVMResource] No agent registered as '$MachineName'. This is already the desired (Absent) state."
            $result.status = [DSCGetSummaryState]::Unchanged
            return $result
        }

        Write-Verbose "[Get-AzDoEnvironmentVMResource] No agent registered as '$MachineName' on environment '$EnvironmentName'. Registration is agent-install-only; DSC cannot create this resource."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'AgentNotRegistered'
        return $result
    }

    $result.liveCache = $resource
    $result.Ensure    = [Ensure]::Present

    $propertiesChanged = @()

    # Tags are compared case-insensitively as a set, and only when the configuration specifies
    # Tags at all - an unset Tags property never reads as "must be empty".
    if ($PSBoundParameters.ContainsKey('Tags'))
    {
        $currentTags = @($resource.tags) | Where-Object { $_ }
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

    Write-Verbose "[Get-AzDoEnvironmentVMResource] VM resource '$MachineName' status: $($result.status)."

    return $result
}
