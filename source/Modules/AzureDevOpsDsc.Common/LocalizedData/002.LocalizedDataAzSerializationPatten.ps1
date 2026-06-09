<#
.SYNOPSIS
    Contains localized data patterns for Azure DevOps serialization.

.DESCRIPTION
    This data section defines regular expression patterns used for matching various Azure DevOps entities such as Git repositories, group permissions, and project permissions.

.NOTES

.DATA
    GitRepository
        Pattern to match Git repository ACL tokens, excluding branch level ACLs.
        Example: repoV2/ProjectId/RepoId
        Excludes: repoV2/ProjectId/RepoId/refs/heads/BranchName

    GroupPermission
        Pattern to match group permissions.
        Example: 78a5065f-3043-426f-9cc5-785748b18f9d\\242ea4ca-e150-4499-a491-00f4ce1f480e

    ProjectPermission
        Pattern to match project permissions.
        Example: $PROJECT:vstfs:///Classification/TeamProject/78a5065f-3043-426f-9cc5-785748b18f9d
#>
data LocalizedDataAzSerializationPatten
{
    @{
        # Git Repository ACL Token Patterns. Exclude the refs token since these are branch level ACLs.
        # Example: repoV2/ProjectId/RepoId
        # Not: repoV2/ProjectId/RepoId/refs/heads/BranchName
        GitRepository = '^repoV2\/{0}\/(?!.*\/refs).*'
        # Group Permissions
        # Example: 78a5065f-3043-426f-9cc5-785748b18f9d\\242ea4ca-e150-4499-a491-00f4ce1f480e
        GroupPermission = '^{0}\\\\{1}$'
        # Project Permissions
        # Example: $PROJECT:vstfs:///Classification/TeamProject/78a5065f-3043-426f-9cc5-785748b18f9d
        ProjectPermission = '^\$PROJECT:vstfs:\/{3}Classification\/TeamProject\/{0}$'
        # Build/Pipeline Permissions  (ProjectId or ProjectId/PipelineId)
        # Example: 78a5065f-3043-426f-9cc5-785748b18f9d  or  78a5065f.../123
        BuildPermission = '^{0}(\/[0-9]+)?$'
        # Library/VariableGroup Permissions
        # Example: Library/Project/ProjectId  or  Library/Project/ProjectId/VariableGroup/42
        LibraryPermission = '^Library\/Project\/{0}(\/VariableGroup\/[0-9]+)?$'
        # ServiceEndpoints Permissions
        # Example: endpoints/Project/ProjectId  or  endpoints/Project/ProjectId/endpoint/EndpointId
        ServiceEndpointPermission = '^endpoints\/Project\/{0}(\/endpoint\/[A-Za-z0-9-]+)?$'
        # AgentPool Permissions  (PoolId integer)
        # Example: 7
        AgentPoolPermission = '^{0}$'
        # DistributedTask/Environment Permissions
        # Example: Environments/ProjectId  or  Environments/ProjectId/42
        EnvironmentPermission = '^Environments\/{0}(\/[0-9]+)?$'
        # Packaging/ArtifactFeed Permissions
        # Example: FeedId  or  Project/FeedId
        PackagingPermission = '^({0}\/)?[A-Za-z0-9-]+$'
        # Generic fallback – exact token match
        GenericPermission = '^{0}$'
    }

}
