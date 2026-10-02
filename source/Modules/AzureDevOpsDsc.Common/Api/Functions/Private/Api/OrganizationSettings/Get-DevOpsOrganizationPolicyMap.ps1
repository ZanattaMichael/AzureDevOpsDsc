<#
.SYNOPSIS
Single source of truth mapping `AzDoOrganizationSettings` policy-backed properties to their
Azure DevOps `OrganizationPolicy` policy names.

.DESCRIPTION
Each entry describes one property that is backed by the organization policy API (written via
`_apis/OrganizationPolicy/Policies/{policyName}`, read via the policy page's data provider, or per policy from the SPS host) rather
than the `_apis/settings/entries/host` mechanism used by the resource's original five properties. The policy names are unverified
candidates (see issue #84); the integration test reads them from a live organization and fails
loudly if a name or route is wrong.

`DefaultValue` is the value the per-policy read route is asked to report for a policy that was
never set: the value the *Policies* page shows for it in a new organization. It is used only when
the page's own routes return no policy data.

.EXAMPLE
Get-DevOpsOrganizationPolicyMap
#>
function Get-DevOpsOrganizationPolicyMap
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    param ()

    return @(
        @{ PropertyName = 'EnableIPConditionalAccessPolicyValidation';  PolicyName = 'Policy.EnforceAADConditionalAccess';             DefaultValue = 'false' }
        @{ PropertyName = 'LogAuditEvents';                             PolicyName = 'Policy.LogAuditEvents';                        DefaultValue = 'false' }
        @{ PropertyName = 'AllowTeamAdminsToInviteUsers';               PolicyName = 'Policy.AllowTeamAdminsInvitationsAccessToken'; DefaultValue = 'true' }
        @{ PropertyName = 'EnableRequestAccess';                        PolicyName = 'Policy.AllowRequestAccessToken';               DefaultValue = 'true' }
        @{ PropertyName = 'EnableArtifactsFeedUpstreamProtection';      PolicyName = 'Policy.ArtifactsExternalPackageProtectionToken'; DefaultValue = 'false' }
    )
}
