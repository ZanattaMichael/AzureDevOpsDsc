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
        [Parameter()][bool]$EnableIPConditionalAccessPolicyValidation,
        [Parameter()][bool]$LogAuditEvents,
        [Parameter()][bool]$AllowTeamAdminsToInviteUsers,
        [Parameter()][bool]$EnableRequestAccess,
        [Parameter()][string]$RequestAccessUrl,
        [Parameter()][bool]$EnableArtifactsFeedUpstreamProtection,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoOrganizationSettings] Updating organization settings."

    $apiUri = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)

    if ($PSBoundParameters.ContainsKey('LogAuditEvents') -and -not $LogAuditEvents)
    {
        Write-Warning "[Set-AzDoOrganizationSettings] LogAuditEvents is being set to `$false. Any AzDoAuditStream configured on this organization will receive no events while auditing is off."
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

    # Organization policies (separate API: PATCH _apis/OrganizationPolicy/Policies/{policyName})
    $policyMap = Get-DevOpsOrganizationPolicyMap
    foreach ($entry in $policyMap)
    {
        if (-not $PSBoundParameters.ContainsKey($entry.PropertyName)) { continue }

        $policyParams = @{
            ApiUri     = $apiUri
            PolicyName = $entry.PolicyName
            Value      = Get-Variable -Name $entry.PropertyName -ValueOnly
        }

        if ($entry.PropertyName -eq 'EnableRequestAccess' -and $PSBoundParameters.ContainsKey('RequestAccessUrl') -and $EnableRequestAccess)
        {
            $policyParams.Url = $RequestAccessUrl
        }

        Set-DevOpsOrganizationPolicy @policyParams
    }

    Write-Verbose "[Set-AzDoOrganizationSettings] Organization settings updated."
}
