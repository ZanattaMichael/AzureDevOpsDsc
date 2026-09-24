Function New-AzDoOrganizationSettings
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
    # Organization Settings cannot be "created" — delegate to Set
    Set-AzDoOrganizationSettings @PSBoundParameters
}
