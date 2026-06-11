Function Set-AzDoCheckConfiguration
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
    Write-Verbose "[Set-AzDoCheckConfiguration] Updating check '$CheckType' on $ResourceType '$TargetResourceName'."

    $cacheKey = '{0}\{1}\{2}\{3}' -f $ProjectName, $ResourceType, $TargetResourceName, $CheckType
    $check = Get-CacheItem -Key $cacheKey -Type 'LiveCheckConfigurations'

    if (-not $check) { Write-Error "[Set-AzDoCheckConfiguration] Check configuration not found."; return }

    $resourceId = $check.resource.id

    $checkTypeMap = @{
        'Approval'          = @{ Id = '8c6f20a7-a545-4486-9777-f762fafe0d4d'; Name = 'Approval' }
        'ExclusiveLock'     = @{ Id = 'fe1de3ee-a436-41b4-bb20-f6eb4cb879a7'; Name = 'Exclusive Lock' }
        'BusinessHours'     = @{ Id = '9db4e9c1-5588-4ee0-bc64-5d00c5abcfb0'; Name = 'Business Hours' }
        'Task Check'        = @{ Id = '4020e66e-f157-4524-8af1-c5fb8d1e4b12'; Name = 'Task Check' }
        'QueryAzureMonitor' = @{ Id = '9aeb1606-d5b5-4b35-ac09-7a38bfa3fc38'; Name = 'Query Azure Monitor Alerts' }
    }
    $checkTypeEntry = if ($checkTypeMap.ContainsKey($CheckType)) { $checkTypeMap[$CheckType] } else { $null }
    $checkTypeId    = if ($checkTypeEntry) { $checkTypeEntry.Id } else { $CheckType }
    $checkTypeName  = if ($checkTypeEntry) { $checkTypeEntry.Name } else { $CheckType }

    $params = @{
        ApiUri           = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName      = $ProjectName
        CheckId          = $check.id
        CheckTypeId      = $checkTypeId
        CheckTypeName    = $checkTypeName
        ResourceType     = $ResourceType
        ResourceId       = $resourceId
        ResourceName     = $TargetResourceName
        Settings         = if ($Settings) { $Settings } else { @{} }
        TimeoutInMinutes = $TimeoutInMinutes
    }

    $value = Set-DevOpsCheckConfiguration @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoCheckConfiguration] Set-DevOpsCheckConfiguration returned null. Check authentication token and organization settings."
        return
    }

    Add-CacheItem -Key $cacheKey -Value $value -Type 'LiveCheckConfigurations'
    Export-CacheObject -CacheType 'LiveCheckConfigurations' -Content $AzDoLiveCheckConfigurations
    Refresh-CacheObject -CacheType 'LiveCheckConfigurations'
}
