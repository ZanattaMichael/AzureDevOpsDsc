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

        # Extract actual live values from the API response
        $liveValues = $settings.value
        $liveAllowPublicProjects        = $liveValues.'Microsoft.VisualStudio.Services.EnablePublicProjects' -eq 'true'
        $liveAllowExternalGuestAccess   = $liveValues.'Microsoft.VisualStudio.Services.Security.EnableAADGuestPolicy' -eq 'false'
        $liveEnableOAuth                = $liveValues.'Microsoft.VisualStudio.Services.Security.EnableOAuthToken' -eq 'true'
        $liveEnableSSH                  = $liveValues.'Microsoft.VisualStudio.Services.Security.EnableSSHPolicy' -eq 'true'
        $liveDisallowAadGuestUserPolicy = $liveValues.'Microsoft.VisualStudio.Services.Security.DisallowAADGuestUserPolicy' -eq 'true'

        $result.AllowPublicProjects        = $liveAllowPublicProjects
        $result.AllowExternalGuestAccess   = $liveAllowExternalGuestAccess
        $result.EnableOAuthAuthentication  = $liveEnableOAuth
        $result.EnableSSHAuthentication    = $liveEnableSSH
        $result.DisallowAadGuestUserPolicy = $liveDisallowAadGuestUserPolicy

        $changed = @()
        if ($PSBoundParameters.ContainsKey('AllowPublicProjects')        -and $liveAllowPublicProjects        -ne $AllowPublicProjects)        { $changed += 'AllowPublicProjects' }
        if ($PSBoundParameters.ContainsKey('AllowExternalGuestAccess')   -and $liveAllowExternalGuestAccess   -ne $AllowExternalGuestAccess)   { $changed += 'AllowExternalGuestAccess' }
        if ($PSBoundParameters.ContainsKey('EnableOAuthAuthentication')  -and $liveEnableOAuth                -ne $EnableOAuthAuthentication)  { $changed += 'EnableOAuthAuthentication' }
        if ($PSBoundParameters.ContainsKey('EnableSSHAuthentication')    -and $liveEnableSSH                  -ne $EnableSSHAuthentication)    { $changed += 'EnableSSHAuthentication' }
        if ($PSBoundParameters.ContainsKey('DisallowAadGuestUserPolicy') -and $liveDisallowAadGuestUserPolicy -ne $DisallowAadGuestUserPolicy) { $changed += 'DisallowAadGuestUserPolicy' }

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
