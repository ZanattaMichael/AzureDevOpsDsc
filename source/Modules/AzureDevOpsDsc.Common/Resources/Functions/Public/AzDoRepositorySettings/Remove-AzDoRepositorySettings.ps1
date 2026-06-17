Function Remove-AzDoRepositorySettings
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$RepositoryName,
        [Parameter()][string]$DefaultBranch = 'main',
        [Parameter()][bool]$AllowSquashMerge = $true,
        [Parameter()][bool]$AllowRebaseMerge = $true,
        [Parameter()][bool]$AllowNoFastForward = $true,
        [Parameter()][bool]$DisableForking = $false,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    # Repository settings cannot be removed; reset to defaults
    Write-Verbose "[Remove-AzDoRepositorySettings] Resetting settings to defaults for '$RepositoryName'."
    $repository = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $RepositoryName) -Type 'LiveRepositories'
    if (-not $repository) { Write-Warning "[Remove-AzDoRepositorySettings] Repository not found."; return }
    $params = @{
        ApiUri             = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName        = $ProjectName
        RepositoryId       = $repository.id
        AllowSquashMerge   = $true
        AllowNoFastForward = $true
        AllowRebaseMerge   = $true
    }
    Set-DevOpsRepositorySettings @params
}
