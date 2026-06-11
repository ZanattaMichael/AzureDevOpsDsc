Function New-AzDoCheckConfiguration
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TargetResourceName,
        [Parameter(Mandatory = $true)][string]$ResourceType,
        [Parameter(Mandatory = $true)][string]$CheckType,
        [Parameter()][HashTable]$Settings,
        [Parameter()][uint32]$TimeoutInMinutes = 43200,
        [Parameter()][bool]$Enabled = $true,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[New-AzDoCheckConfiguration] Creating check '$CheckType' on $ResourceType '$TargetResourceName'."

    # Resolve the resource ID from the appropriate cache
    $resourceId = switch ($ResourceType)
    {
        'environment' {
            $env = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TargetResourceName) -Type 'LivePipelineEnvironments'
            if ($env) { $env.id.ToString() } else { $null }
        }
        'repository' {
            $repo = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TargetResourceName) -Type 'LiveRepositories'
            if ($repo) { $repo.id } else { $null }
        }
        'endpoint' {
            $sc = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TargetResourceName) -Type 'LiveServiceConnections'
            if ($sc) { $sc.id } else { $null }
        }
        default { $TargetResourceName }
    }

    if (-not $resourceId) { Write-Error "[New-AzDoCheckConfiguration] Resource '$TargetResourceName' not found."; return }

    # Map short/camelCase names to the exact display names the Azure DevOps API requires.
    # The API uses type.name to look up metadata; wrong names cause NullReferenceException.
    # Only 'Approval' is verified against the Azure DevOps API. ExclusiveLock was removed for now —
    # its check-type GUID/payload could not be confirmed (the create null-refs). The remaining
    # entries are unverified and kept only as best-known values.
    $checkTypeMap = @{
        'Approval'          = @{ Id = '8c6f20a7-a545-4486-9777-f762fafe0d4d'; Name = 'Approval' }
        'BusinessHours'     = @{ Id = '9db4e9c1-5588-4ee0-bc64-5d00c5abcfb0'; Name = 'Business Hours' }
        'Task Check'        = @{ Id = '4020e66e-f157-4524-8af1-c5fb8d1e4b12'; Name = 'Task Check' }
        'QueryAzureMonitor' = @{ Id = '9aeb1606-d5b5-4b35-ac09-7a38bfa3fc38'; Name = 'Query Azure Monitor Alerts' }
    }

    $checkTypeEntry  = if ($checkTypeMap.ContainsKey($CheckType)) { $checkTypeMap[$CheckType] } else { $null }
    $checkTypeId     = if ($checkTypeEntry) { $checkTypeEntry.Id } else { $CheckType }
    $checkTypeName   = if ($checkTypeEntry) { $checkTypeEntry.Name } else { $CheckType }

    $params = @{
        ApiUri           = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName      = $ProjectName
        CheckTypeId      = $checkTypeId
        CheckTypeName    = $checkTypeName
        ResourceType     = $ResourceType
        ResourceId       = $resourceId
        ResourceName     = $TargetResourceName
        Settings         = if ($Settings) { $Settings } else { @{} }
        TimeoutInMinutes = $TimeoutInMinutes
        Enabled          = $Enabled
    }

    $value = New-DevOpsCheckConfiguration @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoCheckConfiguration] New-DevOpsCheckConfiguration returned null. Check authentication token and organization settings."
        return
    }

    $cacheKey = '{0}\{1}\{2}\{3}' -f $ProjectName, $ResourceType, $TargetResourceName, $CheckType
    Add-CacheItem -Key $cacheKey -Value $value -Type 'LiveCheckConfigurations'
    Export-CacheObject -CacheType 'LiveCheckConfigurations' -Content $AzDoLiveCheckConfigurations
    Refresh-CacheObject -CacheType 'LiveCheckConfigurations'
}
