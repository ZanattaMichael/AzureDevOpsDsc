<#
.SYNOPSIS
Single source of truth mapping `AzDoOrganizationSettings` policy-backed properties to their
Azure DevOps `OrganizationPolicy` policy names.

.DESCRIPTION
Each entry describes one property that is backed by the organization policy API (written via
`_apis/OrganizationPolicy/Policies/{policyName}`, read via the policy page's data provider) rather
than the `_apis/settings/entries/host` mechanism used by the resource's original five properties. The policy names are unverified
candidates (see issue #84); the integration test reads them from a live organization and fails
loudly if a name or route is wrong.

.EXAMPLE
Get-DevOpsOrganizationPolicyMap
#>
function Get-DevOpsOrganizationPolicyMap
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    param ()

    return @(
        @{ PropertyName = 'EnableIPConditionalAccessPolicyValidation';  PolicyName = 'Policy.EnforceAADConditionalAccess' }
        @{ PropertyName = 'LogAuditEvents';                             PolicyName = 'Policy.LogAuditEvents' }
        @{ PropertyName = 'AllowTeamAdminsToInviteUsers';               PolicyName = 'Policy.AllowTeamAdminsInvitationsAccessToken' }
        @{ PropertyName = 'EnableRequestAccess';                        PolicyName = 'Policy.AllowRequestAccessToken' }
        @{ PropertyName = 'EnableArtifactsFeedUpstreamProtection';      PolicyName = 'Policy.ArtifactsExternalPackageProtectionToken' }
    )
}
