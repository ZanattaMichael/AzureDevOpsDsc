$currentFile = $MyInvocation.MyCommand.Path

Describe 'Parse-ACLToken' -Tag "Unit", "ACL", "Helper" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Parse-ACLToken.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }


        $script:LocalizedDataAzACLTokenPatten = @{
            OrganizationGit         = '^org:(.+)$'
            GitProject              = '^project:(.+)$'
            GitRepository           = '^repo:(.+)$'
            GitBranch               = '^branch:(.+)$'
            ResourcePermission      = '^resource:(.+)$'
            GroupPermission         = '^group:(.+)$'
            IterationPathPermission = '^iteration:(.+)$'
            AreaPathPermission      = '^area:(.+)$'
            # Real patterns: the query branch is shape-sensitive (the project id is a GUID
            # too), so stand-in patterns would not exercise what it actually does.
            QueryRootPermission     = '^\$$'
            QueryPermission         = '^\$\/(?<ProjectId>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})(?<Remainder>(\/[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})*)$'
            QueryFolderIdentifier   = '\/(?<identifiers>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})'
            BuildPermission         = '^(?<ProjectId>[A-Za-z0-9-]+)(\/(?<PipelineId>[0-9]+))?$'
            BuildFolderPermission   = '^(?<ProjectId>[A-Za-z0-9-]+)\/(?<FolderPath>(?![0-9]+$).+)$'
            ReleaseDefinitionPermission = '^(?<ProjectId>[A-Za-z0-9-]+)(\/(?<FolderPath>.+?))?\/(?<DefinitionId>[0-9]+)$'
            ReleaseFolderPermission     = '^(?<ProjectId>[A-Za-z0-9-]+)\/(?<FolderPath>(?![0-9]+$).+)$'
            ReleaseRootPermission       = '^(?<ProjectId>[A-Za-z0-9-]+)$'
        }

        # If there were any Mock commands needed, they should be added here using the complete syntax.
        # Example:
        # Mock -CommandName SomeCommand -MockWith {
        #     return "mocked result"
        # }

    }

    It 'Should parse OrganizationGit token correctly' {
        $token = "org:testOrg"
        $SecurityNamespace = "Git Repositories"
        $result = Parse-ACLToken -Token $token -SecurityNamespace $SecurityNamespace

        $result.type | Should -Be 'OrganizationGit'
        $result._token | Should -Be $token
    }

    It 'Should parse GitProject token correctly' {
        $token = "project:testProject"
        $SecurityNamespace = "Git Repositories"
        $result = Parse-ACLToken -Token $token -SecurityNamespace $SecurityNamespace

        $result.type | Should -Be 'GitProject'
        $result._token | Should -Be $token
    }

    It 'Should throw for unrecognized Git Repositories token' {
        $token = "unknown:test"
        $SecurityNamespace = "Git Repositories"
        { Parse-ACLToken -Token $token -SecurityNamespace $SecurityNamespace } | Should -Throw "Token '$token' is not recognized."
    }

    It 'Should parse ResourcePermission token correctly' {
        $token = "resource:testResource"
        $SecurityNamespace = "Identity"
        $result = Parse-ACLToken -Token $token -SecurityNamespace $SecurityNamespace

        $result.type | Should -Be 'ResourcePermission'
        $result._token | Should -Be $token
    }

    It 'Should parse GroupPermission token correctly' {
        $token = "group:testGroup"
        $SecurityNamespace = "Identity"
        $result = Parse-ACLToken -Token $token -SecurityNamespace $SecurityNamespace

        $result.type | Should -Be 'GroupPermission'
        $result._token | Should -Be $token
    }

    It 'Should parse AreaPathPermission token correctly' {
        $token = "area:testArea"
        $SecurityNamespace = "CSS"
        $result = Parse-ACLToken -Token $token -SecurityNamespace $SecurityNamespace

        $result.type | Should -Be 'AreaPathPermission'
        $result._token | Should -Be $token
    }

    It 'Should parse IterationPathPermission token correctly' {
        $token = "iteration:testIteration"
        $SecurityNamespace = "Iteration"
        $result = Parse-ACLToken -Token $token -SecurityNamespace $SecurityNamespace

        $result.type | Should -Be 'IterationPathPermission'
        $result._token | Should -Be $token
    }

    It 'Should throw an error if the AreaPath token is incorrect' {
        $token = "badarea:testArea"
        $SecurityNamespace = "CSS"
        { Parse-ACLToken -Token $token -SecurityNamespace $SecurityNamespace } | Should -Throw "Token '$token' is not recognized."
    }

    It 'Should throw an error if the IterationPath token is incorrect' {
        $token = "badIteration:testIteration"
        $SecurityNamespace = "iteration"
        { Parse-ACLToken -Token $token -SecurityNamespace $SecurityNamespace } | Should -Throw "Token '$token' is not recognized."
    }

    It 'Should parse a project-root Query token' {
        $projectId = [guid]::NewGuid().ToString()
        $result = Parse-ACLToken -Token "`$/$projectId" -SecurityNamespace 'WorkItemQueryFolders'

        $result.type | Should -Be 'QueryPermission'
        $result.ProjectId | Should -Be $projectId
        $result.Identifiers.Count | Should -Be 0
    }

    It 'Should parse a nested Query token into its folder chain' {
        $projectId = [guid]::NewGuid().ToString()
        $folderId1 = [guid]::NewGuid().ToString()
        $folderId2 = [guid]::NewGuid().ToString()

        $result = Parse-ACLToken -Token "`$/$projectId/$folderId1/$folderId2" -SecurityNamespace 'WorkItemQueryFolders'

        $result.ProjectId | Should -Be $projectId
        $result.Identifiers.Count | Should -Be 2
        $result.Identifiers[0].identifier | Should -Be $folderId1
        $result.Identifiers[1].identifier | Should -Be $folderId2
    }

    It 'Should not read the project id as the first folder' {
        $projectId = [guid]::NewGuid().ToString()
        $folderId  = [guid]::NewGuid().ToString()

        $result = Parse-ACLToken -Token "`$/$projectId/$folderId" -SecurityNamespace 'WorkItemQueryFolders'

        $result.Identifiers.identifier | Should -Not -Contain $projectId
    }

    It 'Should parse the namespace root token' {
        # The WorkItemQueryFolders root ACL is a bare '$'. AzDoQueryPermission enumerates
        # every ACL in the namespace, so it meets this on any organization.
        $result = Parse-ACLToken -Token '$' -SecurityNamespace 'WorkItemQueryFolders'
        $result.type | Should -Be 'QueryRoot'
    }

    It 'Should not throw for an unrecognized Query token' {
        # This previously asserted a throw, which is what the integration run disproved:
        # throwing on one unmodelled token aborted the whole ACL scan and failed every
        # AzDoQueryPermission test. Project, Process, Build and Library all tag the token
        # '<Namespace>Unknown' instead, and this namespace now matches them.
        $result = Parse-ACLToken -Token 'not-a-query-token' -SecurityNamespace 'WorkItemQueryFolders'
        $result.type | Should -Be 'QueryUnknown'
    }

    It 'Should parse a Build definition token as a definition' {
        $result = Parse-ACLToken -Token 'project-id-1/123' -SecurityNamespace 'Build'
        $result.type | Should -Be 'Build'
    }

    It 'Should parse a Build folder token as a folder' {
        $result = Parse-ACLToken -Token 'project-id-1/Platform' -SecurityNamespace 'Build'
        $result.type | Should -Be 'BuildFolder'
    }

    It 'Should parse a nested Build folder token as a folder' {
        $result = Parse-ACLToken -Token 'project-id-1/Platform/Release' -SecurityNamespace 'Build'
        $result.type | Should -Be 'BuildFolder'
    }

    It 'Should parse a ReleaseManagement project-root token' {
        $result = Parse-ACLToken -Token 'project-id-1' -SecurityNamespace 'ReleaseManagement'
        $result.type | Should -Be 'ReleaseRoot'
        $result.ProjectId | Should -Be 'project-id-1'
    }

    It 'Should parse a ReleaseManagement definition token at the root' {
        $result = Parse-ACLToken -Token 'project-id-1/123' -SecurityNamespace 'ReleaseManagement'
        $result.type | Should -Be 'ReleaseDefinition'
        $result.ProjectId | Should -Be 'project-id-1'
        $result.DefinitionId | Should -Be '123'
    }

    It 'Should parse a ReleaseManagement definition token inside a folder' {
        $result = Parse-ACLToken -Token 'project-id-1/Platform/123' -SecurityNamespace 'ReleaseManagement'
        $result.type | Should -Be 'ReleaseDefinition'
        $result.FolderPath | Should -Be 'Platform'
        $result.DefinitionId | Should -Be '123'
    }

    It 'Should parse a ReleaseManagement folder token as a folder, not a definition' {
        $result = Parse-ACLToken -Token 'project-id-1/Platform' -SecurityNamespace 'ReleaseManagement'
        $result.type | Should -Be 'ReleaseFolder'
        $result.FolderPath | Should -Be 'Platform'
    }

    It 'Should throw for unrecognized Identity token' {
        $token = "unknown:test"
        $SecurityNamespace = "Identity"
        { Parse-ACLToken -Token $token -SecurityNamespace $SecurityNamespace } | Should -Throw "Token '$token' is not recognized."
    }
}
