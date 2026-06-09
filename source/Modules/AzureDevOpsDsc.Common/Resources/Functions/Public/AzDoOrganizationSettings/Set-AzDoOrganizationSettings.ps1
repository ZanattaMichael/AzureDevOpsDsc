Function Set-AzDoOrganizationSettings
{
    [CmdletBinding()]
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

    Write-Verbose "[Set-AzDoOrganizationSettings] Updating organization settings."

    $settings = @{}
    if ($PSBoundParameters.ContainsKey('AllowPublicProjects'))
        { $settings['Microsoft.VisualStudio.Services.EnablePublicProjects'] = $AllowPublicProjects.ToString().ToLower() }
    if ($PSBoundParameters.ContainsKey('AllowExternalGuestAccess'))
        { $settings['Microsoft.VisualStudio.Services.Security.EnableAADGuestPolicy'] = (!$AllowExternalGuestAccess).ToString().ToLower() }
    if ($PSBoundParameters.ContainsKey('EnableOAuthAuthentication'))
        { $settings['Microsoft.VisualStudio.Services.Security.EnableOAuthToken'] = $EnableOAuthAuthentication.ToString().ToLower() }
    if ($PSBoundParameters.ContainsKey('EnableSSHAuthentication'))
        { $settings['Microsoft.VisualStudio.Services.Security.EnableSSHPolicy'] = $EnableSSHAuthentication.ToString().ToLower() }
    if ($PSBoundParameters.ContainsKey('DisallowAadGuestUserPolicy'))
        { $settings['Microsoft.VisualStudio.Services.Security.DisallowAADGuestUserPolicy'] = $DisallowAadGuestUserPolicy.ToString().ToLower() }

    if ($settings.Count -eq 0)
    {
        Write-Verbose "[Set-AzDoOrganizationSettings] No settings to update."
        return
    }

    $params = @{
        ApiUri   = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        Settings = $settings
    }

    Set-DevOpsOrganizationSettings @params
    Write-Verbose "[Set-AzDoOrganizationSettings] Organization settings updated."
}
