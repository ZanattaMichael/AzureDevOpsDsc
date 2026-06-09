Function Get-AzDoOrganizationSettings
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$OrganizationName,
        [Parameter()][bool]$AllowPublicProjects,
        [Parameter()][bool]$AllowExternalGuestAccess,
        [Parameter()][bool]$EnableOAuthAuthentication,
        [Parameter()][bool]$EnableSSHAuthentication,
        [Parameter()][bool]$DisallowAadGuestUserPolicy,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoOrganizationSettings] Started."

    $result = @{ Ensure = [Ensure]::Present; propertiesChanged = @(); status = $null }

    $params = @{
        ApiUri = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
    }

    try
    {
        $settings = Get-DevOpsOrganizationSettings @params
        $result.liveCache = $settings

        $changed = @()
        # Compare desired vs live — only check params that were explicitly bound
        if ($PSBoundParameters.ContainsKey('AllowPublicProjects') -and
            $settings.'Microsoft.VisualStudio.Services.EnablePublicProjects' -ne $AllowPublicProjects.ToString().ToLower())
        { $changed += 'AllowPublicProjects' }

        $result.propertiesChanged = $changed
        $result.status = if ($changed.Count -eq 0) { [DSCGetSummaryState]::Unchanged } else { [DSCGetSummaryState]::Changed }
    }
    catch
    {
        Write-Warning "[Get-AzDoOrganizationSettings] Could not retrieve settings: $_"
        $result.status = [DSCGetSummaryState]::Error
    }

    return $result
}
