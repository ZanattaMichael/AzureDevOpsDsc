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
        # Each ref path segment beneath refs/heads (or refs/tags) is hex-encoded UTF-16LE, and a
        # branch/tag name with a '/' in it (e.g. 'release/1.0') is TWO encoded segments joined by
        # '/' in the token - so the capture has to span every remaining segment, not just the first.
        GitBranch               = '^(repoV2)\/(?<ProjectId>[A-Za-z0-9-]+)\/(?<RepoId>[A-Za-z0-9-]+)\/refs\/heads\/(?<BranchName>[0-9a-fA-F]+(?:\/[0-9a-fA-F]+)*)$'
        GitTag                  = '^(repoV2)\/(?<ProjectId>[A-Za-z0-9-]+)\/(?<RepoId>[A-Za-z0-9-]+)\/refs\/tags\/(?<TagName>[0-9a-fA-F]+(?:\/[0-9a-fA-F]+)*)$'
        # Identity ACL Token Patterns
        GroupPermission         = '^(?<ProjectId>[A-Za-z0-9-_]+)\\(?<GroupId>[A-Za-z0-9-_]+)$'
        ResourcePermission      = '^(?<ProjectId>[A-Za-z0-9-_]+)$'
        # AreaPath and IterationPath ACL Token Patterns
        AreaPathPermission      = '(vstfs:\/{3}Classification\/Node\/)(?<identifiers>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})'
        IterationPathPermission = '(vstfs:\/{3}Classification\/Node\/)(?<identifiers>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})'
        # Work item query ACL Token Patterns — the namespace root is a bare '$', then
        # $/{projectId} for a project's query root, then one folder GUID per level:
        # $/{projectId}/{folderId}/{subfolderId}
        QueryRootPermission     = '^\$$'
        QueryPermission         = '^\$\/(?<ProjectId>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})(?<Remainder>(\/[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})*)$'
        QueryFolderIdentifier   = '\/(?<identifiers>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})'
        # Project-level ACL Token Patterns
        ProjectPermission       = '^\$PROJECT:vstfs:\/{3}Classification\/TeamProject\/(?<ProjectId>[A-Za-z0-9-]+)$'
        # Process ACL Token Patterns — org-wide root ($PROCESS), or $PROCESS:{parentProcessId}:{processId}
        ProcessRootPermission   = '^\$PROCESS$'
        ProcessPermission       = '^\$PROCESS:(?<ParentProcessId>[A-Za-z0-9-]+):(?<ProcessId>[A-Za-z0-9-]+)$'
        # Build (Pipeline) ACL Token Patterns  — ProjectId only, or ProjectId/PipelineId
        BuildPermission         = '^(?<ProjectId>[A-Za-z0-9-]+)(\/(?<PipelineId>[0-9]+))?$'
        # Build folder ACL token — {projectId}/{folderPath}. The negative lookahead keeps a
        # definition token ({projectId}/{numericId}) from being read as a folder.
        BuildFolderPermission   = '^(?<ProjectId>[A-Za-z0-9-]+)\/(?<FolderPath>(?![0-9]+$).+)$'
        # Release (classic Release Management) ACL Token Patterns. The namespace addresses a
        # project root ({projectId}), a definition ({projectId}/{definitionId}, or
        # {projectId}/{folderPath}/{definitionId} when the definition lives in a folder - the
        # root folder is omitted rather than written out), or a folder on its own
        # ({projectId}/{folderPath}). A definition token always ends in a numeric id; a folder
        # path never does, which is what tells the two apart, the same trick BuildFolderPermission
        # uses.
        ReleaseDefinitionPermission = '^(?<ProjectId>[A-Za-z0-9-]+)(\/(?<FolderPath>.+?))?\/(?<DefinitionId>[0-9]+)$'
        ReleaseFolderPermission     = '^(?<ProjectId>[A-Za-z0-9-]+)\/(?<FolderPath>(?![0-9]+$).+)$'
        ReleaseRootPermission       = '^(?<ProjectId>[A-Za-z0-9-]+)$'
        # Library (VariableGroup) ACL Token Patterns
        LibraryPermission       = '^Library\/Project\/(?<ProjectId>[A-Za-z0-9-]+)(\/VariableGroup\/(?<VariableGroupId>[0-9]+))?(\/SecureFile\/(?<SecureFileId>[A-Za-z0-9-]+))?$'
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
