Function Get-AzDoRepositorySettings
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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

    Write-Verbose "[Get-AzDoRepositorySettings] Started."

    $result = @{ Ensure = [Ensure]::Present; propertiesChanged = @(); status = $null }

    $repository = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $RepositoryName) -Type 'LiveRepositories'

    if (-not $repository)
    {
        Write-Warning "[Get-AzDoRepositorySettings] Repository '$RepositoryName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    try
    {
        $params = @{
            ApiUri       = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
            ProjectName  = $ProjectName
            RepositoryId = $repository.id
        }
        $settings = Get-DevOpsRepositorySettings @params
        $result.liveCache = $settings

        $changed = @()
        if ($settings.allowSquashMerge    -ne $AllowSquashMerge)    { $changed += 'AllowSquashMerge' }
        if ($settings.allowNoFastForward  -ne $AllowNoFastForward)  { $changed += 'AllowNoFastForward' }
        if ($settings.allowRebaseMerge    -ne $AllowRebaseMerge)    { $changed += 'AllowRebaseMerge' }

        $result.propertiesChanged = $changed
        $result.status = if ($changed.Count -eq 0) { [DSCGetSummaryState]::Unchanged } else { [DSCGetSummaryState]::Changed }
    }
    catch
    {
        Write-Warning "[Get-AzDoRepositorySettings] Error retrieving settings: $_"
        $result.status = [DSCGetSummaryState]::Error
    }

    return $result
}
