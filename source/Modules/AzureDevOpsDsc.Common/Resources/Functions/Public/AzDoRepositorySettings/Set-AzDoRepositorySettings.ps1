Function Set-AzDoRepositorySettings
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
    Write-Verbose "[Set-AzDoRepositorySettings] Updating settings for '$RepositoryName'."
    $repository = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $RepositoryName) -Type 'LiveRepositories'
    if (-not $repository) { Write-Error "[Set-AzDoRepositorySettings] Repository not found."; return }
    $params = @{
        ApiUri              = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName         = $ProjectName
        RepositoryId        = $repository.id
        AllowSquashMerge    = $AllowSquashMerge
        AllowNoFastForward  = $AllowNoFastForward
        AllowRebaseMerge    = $AllowRebaseMerge
    }
    Set-DevOpsRepositorySettings @params
    Write-Verbose "[Set-AzDoRepositorySettings] Settings updated for '$RepositoryName'."
}
