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
        GitRepository       = '(?<ProjectName>[A-Za-z0-9-_]+)(\/|\\)(?<GitRepoName>[A-Za-z0-9-_]+)'
        # Identity ACL Token Patterns
        GroupPermission     = '^(?<ProjectId>[A-Za-z0-9-_]+)\\(?<GroupId>[A-Za-z0-9-_]+)$'
        ResourcePermission  = '^\(\?<ProjectId>[A-Za-z0-9-_]+\)$'
        ProjectPermission   = '^\$PROJECT:vstfs:\/{3}Classification\/TeamProject\/(?<ProjectId>[A-Za-z0-9-_]+)$'
        # AreaPath and IterationPath ACL Token Patterns
        AreaPathPermission      = '(vstfs:\/{3}Classification\/Node\/)(?<identifiers>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})'
        IterationPathPermission = '(vstfs:\/{3}Classification\/Node\/)(?<identifiers>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})'
    }

}
