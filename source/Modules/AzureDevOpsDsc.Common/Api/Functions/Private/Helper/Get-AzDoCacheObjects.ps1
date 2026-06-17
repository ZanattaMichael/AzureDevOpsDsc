<#
.SYNOPSIS
Retrieves a list of Azure DevOps cache object types.

.DESCRIPTION
The Get-AzDoCacheObjects function returns an array of strings representing different types of cache objects used in Azure DevOps.

.OUTPUTS
String[]
An array of strings representing the cache object types.

.EXAMPLE
PS> Get-AzDoCacheObjects
This command retrieves the list of Azure DevOps cache object types.

#>
function Get-AzDoCacheObjects
{
    return @(
        # Legacy / non-prefixed types
        'Project',
        'Team',
        'Group',
        'SecurityDescriptor',
        'SecurityNamespaces',

        # Live cache types
        'LiveACLList',
        'LiveAgentPools',
        'LiveAgentQueues',
        'LiveAreaNodes',
        'LiveArtifactFeeds',
        'LiveAuditStreams',
        'LiveBranchPolicies',
        'LiveCheckConfigurations',
        'LiveDeploymentGroups',
        'LiveEnvironmentApprovals',
        'LiveExtensions',
        'LiveGroupMembers',
        'LiveGroups',
        'LiveIterations',
        'LiveNotificationSubscriptions',
        'LivePipelineEnvironments',
        'LivePipelines',
        'LivePolicyTypes',
        'LiveProcesses',
        'LiveProjects',
        'LiveRepositories',
        'LiveServiceConnections',
        'LiveServicePrinciples',
        'LiveTaskGroups',
        'LiveTeamMembers',
        'LiveTeams',
        'LiveUsers',
        'LiveVariableGroups',
        'LiveWikis'
    )
}
