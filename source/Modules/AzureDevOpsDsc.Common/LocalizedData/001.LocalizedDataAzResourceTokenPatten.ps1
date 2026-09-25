<#
.SYNOPSIS
    Contains localized data for Azure DevOps resource token patterns.

.DESCRIPTION
    This data section defines various regular expression patterns used for matching Azure DevOps resource tokens.
    These patterns are used to identify and extract information from different Azure DevOps resources such as organizations, projects, repositories, and permissions.

.KEYWORDS
    Azure DevOps, Regular Expressions, Token Patterns, Localization

.NOTES
    Filepath: /c:/Git/AzureDevOpsDsc/source/Modules/AzureDevOpsDsc.Common/LocalizedData/001.LocalizedDataAzResourceTokenPatten.ps1

.EXAMPLES
    # Example usage of the data section
    $localizedData = LocalizedDataAzResourceTokenPatten
    $orgPattern = $localizedData.OrganizationGit
    $projectPattern = $localizedData.GitProject
    $repoPattern = $localizedData.GitRepository
    $groupPermissionPattern = $localizedData.GroupPermission
    $resourcePermissionPattern = $localizedData.ResourcePermission
    $projectPermissionPattern = $localizedData.ProjectPermission
#>

data LocalizedDataAzResourceTokenPatten
{
    @{
        # Git ACL Token Patterns
        OrganizationGit     = '^azdoorg$'
        GitProject          = '^(repoV2)(\/|\\)(?<ProjectName>[A-Za-z0-9-_]+)'
        # Branch/tag forms are checked before the bare repository form (which has no trailing
        # anchor and would otherwise match just the '{Project}\{Repo}' prefix of either one).
        # The ref name itself is captured as-written (human-readable, e.g. 'release/1.0') - the
        # per-segment hex/UTF-16LE encoding happens only when building the API-side token.
        GitBranch           = '^(?<ProjectName>[A-Za-z0-9-_]+)(\/|\\)(?<GitRepoName>[A-Za-z0-9-_]+)(\/|\\)refs(\/|\\)heads(\/|\\)(?<BranchName>.+)$'
        GitTag              = '^(?<ProjectName>[A-Za-z0-9-_]+)(\/|\\)(?<GitRepoName>[A-Za-z0-9-_]+)(\/|\\)refs(\/|\\)tags(\/|\\)(?<TagName>.+)$'
        GitRepository       = '(?<ProjectName>[A-Za-z0-9-_]+)(\/|\\)(?<GitRepoName>[A-Za-z0-9-_]+)'
        # Identity ACL Token Patterns
        GroupPermission     = '^(?<ProjectId>[A-Za-z0-9-_]+)\\(?<GroupId>[A-Za-z0-9-_]+)$'
        ResourcePermission  = '^\(\?<ProjectId>[A-Za-z0-9-_]+\)$'
        ProjectPermission   = '^\$PROJECT:vstfs:\/{3}Classification\/TeamProject\/(?<ProjectId>[A-Za-z0-9-_]+)$'
        # Tagging Token Patterns — '/{projectId}' (project-scoped token, addressed by id like Project)
        TaggingPermission       = '^\/(?<ProjectId>[A-Za-z0-9-_]+)$'
        # Analytics Token Patterns — '$/{projectId}'
        AnalyticsPermission     = '^\$\/(?<ProjectId>[A-Za-z0-9-_]+)$'
        # AnalyticsViews Token Patterns — '$/Shared/{projectId}'
        AnalyticsViewsPermission = '^\$\/Shared\/(?<ProjectId>[A-Za-z0-9-_]+)$'
        # AreaPath and IterationPath ACL Token Patterns
        AreaPathPermission      = '(vstfs:\/{3}Classification\/Node\/)(?<identifiers>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})'
        IterationPathPermission = '(vstfs:\/{3}Classification\/Node\/)(?<identifiers>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})'
        # Work item query ACL Token Patterns — the namespace root is a bare '$', then
        # $/{projectId} for a project's query root, then one folder GUID per level:
        # $/{projectId}/{folderId}/{subfolderId}
        QueryRootPermission     = '^\$$'
        QueryPermission         = '^\$\/(?<ProjectId>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})(?<Remainder>(\/[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})*)$'
        QueryFolderIdentifier   = '\/(?<identifiers>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})'
        # Build (Pipeline) Token Patterns — ProjectName only, or ProjectName/PipelineName
        BuildPermission         = '^(?<ProjectName>[A-Za-z0-9-_]+)(\/(?<PipelineName>[A-Za-z0-9-_ ]+))?$'
        # Build folder token — {projectName}/\{folderPath}. The leading backslash on the folder
        # path is required: BuildPermission matches pipeline NAMES, so without a marker
        # 'MyProject/Platform' is ambiguous between a folder and a pipeline called 'Platform'.
        BuildFolderPermission   = '^(?<ProjectName>[A-Za-z0-9-_]+)\/(?<FolderPath>\\.+)$'
        # Release (classic Release Management) Token Patterns. Folder tokens are marked the same
        # way as Build folders: {projectName}/\{folderPath}. A definition name is free text too,
        # and a definition can live in a folder, so its token carries a leading '@' immediately
        # before the definition name to tell the two apart:
        # {projectName}/@{definitionName} at the root, or
        # {projectName}/\{folderPath}\@{definitionName} inside a folder.
        ReleaseDefinitionPermission = '^(?<ProjectName>[A-Za-z0-9-_]+)\/(?<FolderPath>\\.+\\)?@(?<DefinitionName>[A-Za-z0-9-_ ]+)$'
        ReleaseFolderPermission     = '^(?<ProjectName>[A-Za-z0-9-_]+)\/(?<FolderPath>\\.+)$'
        ReleaseRootPermission       = '^(?<ProjectName>[A-Za-z0-9-_]+)$'
        # Library (VariableGroup) Token Patterns
        LibraryPermission       = '^Library\/Project\/(?<ProjectName>[A-Za-z0-9-_]+)(\/VariableGroup\/(?<VariableGroupName>[A-Za-z0-9-_ ]+))?(\/SecureFile\/(?<SecureFileName>[A-Za-z0-9-_. ]+))?$'
        # ServiceEndpoints Token Patterns
        ServiceEndpointPermission = '^endpoints\/Project\/(?<ProjectName>[A-Za-z0-9-_]+)(\/endpoint\/(?<EndpointName>[A-Za-z0-9-_ ]+))?$'
        # DistributedTask — AgentPool Token
        AgentPoolPermission     = '^(?<PoolName>[A-Za-z0-9-_ ]+)$'
        # DistributedTask — Environment Token
        EnvironmentPermission   = '^Environments\/(?<ProjectName>[A-Za-z0-9-_]+)(\/(?<EnvironmentName>[A-Za-z0-9-_ ]+))?$'
        # Generic / passthrough
        GenericPermission       = '^(?<Token>.+)$'
    }

}
