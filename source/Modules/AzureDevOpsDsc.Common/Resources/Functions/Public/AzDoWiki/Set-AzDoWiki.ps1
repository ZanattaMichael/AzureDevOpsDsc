Function Set-AzDoWiki
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$WikiName,
        [Parameter()][string]$WikiType = 'projectWiki',
        [Parameter()][string]$RepositoryName,
        [Parameter()][string]$MappedPath = '/',
        [Parameter()][string]$Version,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    # Wiki names/types cannot be changed once created; re-create if needed.
    Write-Verbose "[Set-AzDoWiki] Wiki properties cannot be updated in-place. No action taken."
}
