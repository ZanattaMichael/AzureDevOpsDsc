Function New-AzDoRepositorySettings
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
    # Repository settings always exist — delegate to Set
    Set-AzDoRepositorySettings @PSBoundParameters
}
