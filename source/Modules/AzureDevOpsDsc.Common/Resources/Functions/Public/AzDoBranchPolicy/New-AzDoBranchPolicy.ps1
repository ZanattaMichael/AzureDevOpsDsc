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

    # Look up the policy type by name, falling back to a live API call if not cached
    $policyTypeObj = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PolicyType) -Type 'LivePolicyTypes'

    if (-not $policyTypeObj)
    {
        Write-Verbose "[New-AzDoBranchPolicy] PolicyType '$PolicyType' not in cache, querying API."
        $orgUri = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        # Map camelCase/short names to actual Azure DevOps display names returned by the API
        $policyDisplayNameAliases = @{
            'MinimumReviewerCount' = 'Minimum number of reviewers'
            'BuildValidation'      = 'Build'
            'CommentRequirements'  = 'Comment requirements'
            'WorkItemLinking'      = 'Work item linking'
            'MergeStrategy'        = 'Require a merge strategy'
            'StatusCheck'          = 'Status'
        }
        $lookupName = if ($policyDisplayNameAliases.ContainsKey($PolicyType)) { $policyDisplayNameAliases[$PolicyType] } else { $PolicyType }
        $policyTypes = List-DevOpsPolicyTypes -ApiUri $orgUri -ProjectName $ProjectName
        $policyTypeObj = $policyTypes | Where-Object { $_.displayName -eq $lookupName }
        # Also store using both the short name and the actual display name as keys
        if ($policyTypeObj)
        {
            foreach ($pt in $policyTypes)
            {
                Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $pt.displayName) -Value $pt -Type 'LivePolicyTypes' -SuppressWarning
            }
        }
    }

    # Fall back to well-known policy type GUIDs (Azure DevOps built-in types)
    if (-not $policyTypeObj)
    {
        $wellKnownTypeIds = @{
            'MinimumReviewerCount' = 'fa4e907d-c16b-452d-8106-7efa0cb84489'
            'BuildValidation'      = '0609b952-1397-4640-95ec-e00a01b2f659'
            'CommentRequirements'  = 'c6a1889d-b943-4856-b76f-9e46bb6b0df3'
            'WorkItemLinking'      = '40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e'
        }
        if ($wellKnownTypeIds.ContainsKey($PolicyType))
        {
            $policyTypeObj = [PSCustomObject]@{ id = $wellKnownTypeIds[$PolicyType]; displayName = $PolicyType }
        }
    }

    if (-not $policyTypeObj)
    {
        Write-Error "[New-AzDoBranchPolicy] PolicyType '$PolicyType' not found in cache, API, or well-known types."
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
