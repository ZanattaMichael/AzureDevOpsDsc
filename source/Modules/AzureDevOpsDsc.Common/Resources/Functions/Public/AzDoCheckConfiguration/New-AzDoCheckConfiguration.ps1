Function New-AzDoCheckConfiguration
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$ResourceName,
        [Parameter(Mandatory = $true)][string]$ResourceType,
        [Parameter(Mandatory = $true)][string]$CheckType,
        [Parameter()][HashTable]$Settings,
        [Parameter()][uint32]$TimeoutInMinutes = 43200,
        [Parameter()][bool]$Enabled = $true,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[New-AzDoCheckConfiguration] Creating check '$CheckType' on $ResourceType '$ResourceName'."

    # Resolve the resource ID from the appropriate cache
    $resourceId = switch ($ResourceType)
    {
        'environment' {
            $env = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ResourceName) -Type 'LivePipelineEnvironments'
            if ($env) { $env.id.ToString() } else { $null }
        }
        'repository' {
            $repo = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ResourceName) -Type 'LiveRepositories'
            if ($repo) { $repo.id } else { $null }
        }
        'endpoint' {
            $sc = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ResourceName) -Type 'LiveServiceConnections'
            if ($sc) { $sc.id } else { $null }
        }
        default { $ResourceName }
    }

    if (-not $resourceId) { Write-Error "[New-AzDoCheckConfiguration] Resource '$ResourceName' not found."; return }

    # Look up a known check type ID (common ones)
    $checkTypeId = switch ($CheckType)
    {
        'Approval'           { '8c6f20a7-a545-4486-9777-f762fafe0d4d' }
        'ExclusiveLock'      { 'fe1de3ee-a436-41b4-bb20-f6eb4cb879a7' }
        'BusinessHours'      { '9db4e9c1-5588-4ee0-bc64-5d00c5abcfb0' }
        'Task Check'         { '4020e66e-f157-4524-8af1-c5fb8d1e4b12' }
        'QueryAzureMonitor'  { '9aeb1606-d5b5-4b35-ac09-7a38bfa3fc38' }
        default              { $CheckType } # Caller may pass a raw GUID
    }

    $params = @{
        ApiUri           = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName      = $ProjectName
        CheckTypeId      = $checkTypeId
        CheckTypeName    = $CheckType
        ResourceType     = $ResourceType
        ResourceId       = $resourceId
        Settings         = if ($Settings) { $Settings } else { @{} }
        TimeoutInMinutes = $TimeoutInMinutes
    }

    $value = New-DevOpsCheckConfiguration @params

    $cacheKey = '{0}\{1}\{2}\{3}' -f $ProjectName, $ResourceType, $ResourceName, $CheckType
    Add-CacheItem -Key $cacheKey -Value $value -Type 'LiveCheckConfigurations'
    Export-CacheObject -CacheType 'LiveCheckConfigurations' -Content $AzDoLiveCheckConfigurations
    Refresh-CacheObject -CacheType 'LiveCheckConfigurations'
}
