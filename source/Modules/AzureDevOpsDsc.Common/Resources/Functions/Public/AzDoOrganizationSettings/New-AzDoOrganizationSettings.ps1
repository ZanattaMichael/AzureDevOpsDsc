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
    # Organization Settings cannot be "created" — delegate to Set
    Set-AzDoOrganizationSettings @PSBoundParameters
}
