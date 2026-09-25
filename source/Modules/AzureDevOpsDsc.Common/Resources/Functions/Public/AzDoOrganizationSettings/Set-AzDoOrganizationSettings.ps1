Function Set-AzDoOrganizationSettings
{
    [CmdletBinding()]
    param (
        [Parameter()][string]$OrganizationName,
        [Parameter()][bool]$AllowPublicProjects,
        [Parameter()][bool]$AllowExternalGuestAccess,
        [Parameter()][bool]$EnableOAuthAuthentication,
        [Parameter()][bool]$EnableSSHAuthentication,
        [Parameter()][bool]$DisallowAadGuestUserPolicy,
        [Parameter()][string]$EnableIPConditionalAccessPolicyValidation,
        [Parameter()][string]$LogAuditEvents,
        [Parameter()][string]$AllowTeamAdminsToInviteUsers,
        [Parameter()][string]$EnableRequestAccess,
        [Parameter()][string]$RequestAccessUrl,
        [Parameter()][string]$EnableArtifactsFeedUpstreamProtection,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoOrganizationSettings] Updating organization settings."

    $apiUri = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)

    if ($LogAuditEvents -eq 'false')
    {
        Write-Warning "[Set-AzDoOrganizationSettings] LogAuditEvents is being set to 'false'. Any AzDoAuditStream configured on this organization will receive no events while auditing is off."
    }

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

    if ($settings.Count -gt 0)
    {
        $params = @{
            ApiUri   = $apiUri
            Settings = $settings
        }
        Set-DevOpsOrganizationSettings @params
    }
    else
    {
        Write-Verbose "[Set-AzDoOrganizationSettings] No host settings to update."
    }

    # Organization policies (separate API: PATCH _apis/OrganizationPolicy/Policies/{policyName}).
    # '' means unmanaged: the policy is left as it is.
    foreach ($entry in (Get-DevOpsOrganizationPolicyMap))
    {
        $desiredValue = Get-Variable -Name $entry.PropertyName -ValueOnly
        if ([string]::IsNullOrEmpty($desiredValue)) { continue }

        $policyParams = @{
            ApiUri     = $apiUri
            PolicyName = $entry.PolicyName
            Value      = ($desiredValue -eq 'true')
        }

        if ($entry.PropertyName -eq 'EnableRequestAccess' -and $EnableRequestAccess -eq 'true' -and -not [string]::IsNullOrEmpty($RequestAccessUrl))
        {
            $policyParams.Url = $RequestAccessUrl
        }

        Set-DevOpsOrganizationPolicy @policyParams
    }

    Write-Verbose "[Set-AzDoOrganizationSettings] Organization settings updated."
}
