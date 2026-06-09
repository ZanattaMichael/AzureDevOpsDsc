Function New-AzDoBranchPolicy
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$RepositoryName,
        [Parameter(Mandatory = $true)][string]$BranchName,
        [Parameter(Mandatory = $true)][string]$PolicyType,
        [Parameter()][bool]$isEnabled = $true,
        [Parameter()][bool]$isBlocking = $true,
        [Parameter()][HashTable]$PolicySettings,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoBranchPolicy] Creating branch policy '$PolicyType' on '$BranchName'."

    $project    = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    $repository = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $RepositoryName) -Type 'LiveRepositories'

    if ((-not $project) -or (-not $repository))
    {
        Write-Error "[New-AzDoBranchPolicy] Project or Repository not found in cache."
        return
    }

    # Build the scope/settings for the policy
    $settings = if ($PolicySettings) { $PolicySettings } else { @{} }
    if (-not $settings.ContainsKey('scope'))
    {
        $settings['scope'] = @(
            @{
                repositoryId = $repository.id
                refName      = 'refs/heads/{0}' -f $BranchName.TrimStart('refs/heads/')
                matchKind    = 'exact'
            }
        )
    }

    # Look up the policy type by name
    $policyTypeObj = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PolicyType) -Type 'LivePolicyTypes'

    if (-not $policyTypeObj)
    {
        Write-Error "[New-AzDoBranchPolicy] PolicyType '$PolicyType' not found in cache."
        return
    }

    $params = @{
        ApiUri       = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName  = $ProjectName
        PolicyTypeId = $policyTypeObj.id
        IsEnabled    = $isEnabled
        IsBlocking   = $isBlocking
        Settings     = $settings
    }

    $value = New-DevOpsBranchPolicy @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoBranchPolicy] New-DevOpsBranchPolicy returned null. Check authentication token and organization settings."
        return
    }

    $cacheKey = '{0}\{1}\{2}\{3}' -f $ProjectName, $RepositoryName, $BranchName, $PolicyType
    Add-CacheItem -Key $cacheKey -Value $value -Type 'LiveBranchPolicies'
    Export-CacheObject -CacheType 'LiveBranchPolicies' -Content $AzDoLiveBranchPolicies
    Refresh-CacheObject -CacheType 'LiveBranchPolicies'
    Write-Verbose "[New-AzDoBranchPolicy] Branch policy created."
}
