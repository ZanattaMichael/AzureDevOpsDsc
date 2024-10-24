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
    }

}
