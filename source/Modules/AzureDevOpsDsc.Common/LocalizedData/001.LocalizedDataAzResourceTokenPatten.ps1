data LocalizedDataAzResourceTokenPatten
{
@'

#
# Git ACL Token Patterns
#

# Organizational Level Token
OrganizationGit = \^azdoorg\$
# Project-Level Git Repository Token
GitProject = \^\(\?<ProjectId>\[A-Za-z0-9-]\+\)\$
# Git Repository Token
GitRepository = \(\?<ProjectName>\[A-Za-z0-9-_]\+\)\(\\/\|\\\\\)\(\?<GitRepoName>\[A-Za-z0-9-_]\+\)

#
# Identity Permissions

# Group Permission
GroupPermission = \^\(\?<ProjectId>\[A-Za-z0-9-_]\+\)\\\\(\?<GroupId>\[A-Za-z0-9-_]\+\)\$

# Project Permissions
ProjectPermission = \^\\\$PROJECT:vstfs:\\/\{3}Classification\\/TeamProject\\/\(\?<ProjectId>\[A-Za-z0-9-_]\+\)\$

'@ | ConvertFrom-StringData
}
