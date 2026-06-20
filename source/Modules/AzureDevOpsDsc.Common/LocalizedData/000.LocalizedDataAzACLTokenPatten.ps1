<#
.SYNOPSIS
    Contains localized data for Azure DevOps ACL token patterns.

.DESCRIPTION
    This data section defines various regular expression patterns used for matching Azure DevOps ACL tokens.
    These patterns are used to identify and extract information from different components such as organizations,
    projects, repositories, branches, groups, and resources within Azure DevOps.

.KEYWORDS
    Azure DevOps, ACL, Token Patterns, Regular Expressions

.EXAMPLES
    The patterns can be used to match and extract information from ACL tokens in Azure DevOps:

    - OrganizationGit: Matches the organization token.
    - GitProject: Matches the project token and extracts the ProjectId.
    - GitRepository: Matches the repository token and extracts the ProjectId and RepoId.
    - GitBranch: Matches the branch token and extracts the ProjectId, RepoId, and BranchName.
    - GroupPermission: Matches the group permission token and extracts the ProjectId and GroupId.
    - ResourcePermission: Matches the resource permission token and extracts the ProjectId.
#>
data LocalizedDataAzACLTokenPatten
{
    @{
        # Git ACL Token Patterns
        OrganizationGit         = '^repoV2$'
        GitProject              = '^(repoV2)\/(?<ProjectId>[A-Za-z0-9-]+)$'
        GitRepository           = '^(repoV2)\/(?<ProjectId>[A-Za-z0-9-]+)\/(?<RepoId>[A-Za-z0-9-]+)$'
        GitBranch               = '^(repoV2)\/(?<ProjectId>[A-Za-z0-9-]+)\/(?<RepoId>[A-Za-z0-9-]+)\/refs\/heads\/(?<BranchName>[A-Za-z0-9]+)'
        # Identity ACL Token Patterns
        GroupPermission         = '^(?<ProjectId>[A-Za-z0-9-_]+)\\(?<GroupId>[A-Za-z0-9-_]+)$'
        ResourcePermission      = '^(?<ProjectId>[A-Za-z0-9-_]+)$'
        # AreaPath and IterationPath ACL Token Patterns
        AreaPathPermission      = '(vstfs:\/{3}Classification\/Node\/)(?<identifiers>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})'
        IterationPathPermission = '(vstfs:\/{3}Classification\/Node\/)(?<identifiers>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})'
        # Project-level ACL Token Patterns
        ProjectPermission       = '^\$PROJECT:vstfs:\/{3}Classification\/TeamProject\/(?<ProjectId>[A-Za-z0-9-]+)$'
        # Process ACL Token Patterns — org-wide root ($PROCESS), or $PROCESS:{parentProcessId}:{processId}
        ProcessRootPermission   = '^\$PROCESS$'
        ProcessPermission       = '^\$PROCESS:(?<ParentProcessId>[A-Za-z0-9-]+):(?<ProcessId>[A-Za-z0-9-]+)$'
        # Build (Pipeline) ACL Token Patterns  — ProjectId only, or ProjectId/PipelineId
        BuildPermission         = '^(?<ProjectId>[A-Za-z0-9-]+)(\/(?<PipelineId>[0-9]+))?$'
        # Library (VariableGroup) ACL Token Patterns
        LibraryPermission       = '^Library\/Project\/(?<ProjectId>[A-Za-z0-9-]+)(\/VariableGroup\/(?<VariableGroupId>[0-9]+))?$'
        # ServiceEndpoints ACL Token Patterns
        ServiceEndpointPermission = '^endpoints\/Project\/(?<ProjectId>[A-Za-z0-9-]+)(\/endpoint\/(?<EndpointId>[A-Za-z0-9-]+))?$'
        # DistributedTask — Agent Pool ACL Token Patterns
        AgentPoolPermission     = '^(?<PoolId>[0-9]+)$'
        # DistributedTask — Environment ACL Token Patterns
        EnvironmentPermission   = '^Environments\/(?<ProjectId>[A-Za-z0-9-]+)(\/(?<EnvironmentId>[0-9]+))?$'
        # Generic / passthrough — any token not matched above
        GenericPermission       = '^(?<Token>.+)$'
    }
}
