Function New-AzDoOrganizationSettings
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
    # Organization Settings cannot be "created" — delegate to Set
    Set-AzDoOrganizationSettings @PSBoundParameters
}
