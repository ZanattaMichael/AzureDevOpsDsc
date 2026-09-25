$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-ACLToken Function Tests' -Tag "Unit", "ACL", "Helper" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-ACLToken.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load 001.LocalizedDataAzResourceTokenPatten
        . (Get-ClassFilePath '001.LocalizedDataAzResourceTokenPatten')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-FunctionItem 'Resolve-AzDoProjectIdForToken.ps1')

        Mock -CommandName Get-CacheItem -MockWith {
            return [PSCustomObject]@{id = "1234"}
        }
        Mock -CommandName Write-Warning

    }

    Context 'Git Repositories Namespace' {

        It 'Should return GitOrganization type for valid Git organization token' {
            $result = New-ACLToken -SecurityNamespace 'Git Repositories' -TokenName 'azdoorg'
            $result.type | Should -Be 'GitOrganization'
        }

        It 'Should return "GitUnknown" type for invalid Git organization token' {
            $result = New-ACLToken -SecurityNamespace 'Git Repositories' -TokenName 'Invalid-Organization'
            $result.type | Should -Be 'GitUnknown'
        }

        It 'Should return GitProject type for valid Git project token' {
            $result = New-ACLToken -SecurityNamespace 'Git Repositories' -TokenName 'repov2/ProjectName'
            $result.type | Should -Be 'GitProject'
            $result.projectId | Should -Be '1234'
        }

        It 'Should return GitRepository type for valid Git repository token' {
            $result = New-ACLToken -SecurityNamespace 'Git Repositories' -TokenName '[OrgName]/ProjectName/RepoName'
            $result.type | Should -Be 'GitRepository'
            $result.projectId | Should -Be '1234'
            $result.RepoId | Should -Be '1234'
        }

        It 'Should return GitUnknown type for unknown Git token' {
            $result = New-ACLToken -SecurityNamespace 'Git Repositories' -TokenName 'Unknown-Token'
            $result.type | Should -Be 'GitUnknown'
        }
    }

    Context 'Git Repositories Namespace - Branch and Tag tokens' {

        BeforeAll {
            . (Get-FunctionItem 'ConvertTo-GitRefToken.ps1').FullName
            . (Get-FunctionItem 'ConvertFrom-GitRefToken.ps1').FullName
            . (Get-FunctionItem 'ConvertTo-FormattedToken.ps1').FullName
            . (Get-FunctionItem 'Parse-ACLToken.ps1').FullName
            . (Get-ClassFilePath '000.LocalizedDataAzACLTokenPatten')
        }

        It 'Should return GitBranch type for a single-segment branch token' {
            $result = New-ACLToken -SecurityNamespace 'Git Repositories' -TokenName 'MyProject/MyRepo/refs/heads/main'
            $result.type | Should -Be 'GitBranch'
            $result.projectId | Should -Be '1234'
            $result.RepoId | Should -Be '1234'
            $result.BranchName | Should -Be 'main'
        }

        It 'Should return GitBranch type for a multi-segment branch token' {
            $result = New-ACLToken -SecurityNamespace 'Git Repositories' -TokenName 'MyProject/MyRepo/refs/heads/release/1.0'
            $result.type | Should -Be 'GitBranch'
            $result.BranchName | Should -Be 'release/1.0'
        }

        It 'Should return GitTag type for a tag token' {
            $result = New-ACLToken -SecurityNamespace 'Git Repositories' -TokenName 'MyProject/MyRepo/refs/tags/v1.0'
            $result.type | Should -Be 'GitTag'
            $result.projectId | Should -Be '1234'
            $result.RepoId | Should -Be '1234'
            $result.TagName | Should -Be 'v1.0'
        }

        It 'Round-trips a single-segment branch token through the API token form and back' {
            # New-ACLToken, ConvertTo-FormattedToken and Parse-ACLToken have to agree (CLAUDE.md
            # gotcha #6): if they disagree, a permission written by Set() never matches the ACL
            # read back by Get() and the resource reports drift forever.
            $structured = New-ACLToken -SecurityNamespace 'Git Repositories' -TokenName 'MyProject/MyRepo/refs/heads/main'
            $apiToken   = ConvertTo-FormattedToken -Token $structured
            $apiToken   | Should -Be 'repoV2/1234/1234/refs/heads/6d00610069006e00'

            $parsed = Parse-ACLToken -Token $apiToken -SecurityNamespace 'Git Repositories'
            $parsed.type | Should -Be 'GitBranch'
            $parsed.BranchName | Should -Be 'main'
        }

        It 'Round-trips a multi-segment (branch folder) token through the API token form and back' {
            $structured = New-ACLToken -SecurityNamespace 'Git Repositories' -TokenName 'MyProject/MyRepo/refs/heads/release/1.0'
            $apiToken   = ConvertTo-FormattedToken -Token $structured

            $parsed = Parse-ACLToken -Token $apiToken -SecurityNamespace 'Git Repositories'
            $parsed.type | Should -Be 'GitBranch'
            $parsed.BranchName | Should -Be 'release/1.0'
        }

        It 'Round-trips a non-ASCII branch name through the API token form and back' {
            $structured = New-ACLToken -SecurityNamespace 'Git Repositories' -TokenName 'MyProject/MyRepo/refs/heads/función'
            $apiToken   = ConvertTo-FormattedToken -Token $structured

            $parsed = Parse-ACLToken -Token $apiToken -SecurityNamespace 'Git Repositories'
            $parsed.type | Should -Be 'GitBranch'
            $parsed.BranchName | Should -Be 'función'
        }

        It 'Round-trips a tag token through the API token form and back' {
            $structured = New-ACLToken -SecurityNamespace 'Git Repositories' -TokenName 'MyProject/MyRepo/refs/tags/v1.0'
            $apiToken   = ConvertTo-FormattedToken -Token $structured

            $parsed = Parse-ACLToken -Token $apiToken -SecurityNamespace 'Git Repositories'
            $parsed.type | Should -Be 'GitTag'
            $parsed.TagName | Should -Be 'v1.0'
        }
    }

    Context 'Identity Namespace' {

        It 'Should return GitGroupPermission type for valid identity group token' {
            $result = New-ACLToken -SecurityNamespace 'Identity' -TokenName '[ProjectId]\[GroupId]'
            $result.type | Should -Be 'Identity'
            $result.projectId | Should -Be 'ProjectId'
            $result.groupId | Should -Be 'GroupId'
        }

        It 'Should return GroupUnknown type for unknown identity token' {
            $result = New-ACLToken -SecurityNamespace 'Identity' -TokenName 'Unknown/Token'
            $result.type | Should -Be 'GroupUnknown'
        }
    }

    Context 'CSS Namespace' {

        It "Returns type as 'Unknown CSS'" {
            $result =  New-ACLToken -SecurityNamespace 'CSS' -TokenName 'bad-token'
            $result.type | Should -Be 'Unknown CSS'
        }

        It "Returns type as 'CSS' and correct identifiers" {
            $mockId = [guid]::NewGuid().ToString()
            $TokenName = "vstfs:///Classification/Node/$mockId"
            $result = New-ACLToken -SecurityNamespace 'CSS' -TokenName $TokenName

            $result.type | Should -Be 'CSS'
            $result.Identifiers.identifier | Should -Be $mockId
        }

        It "Results the correct Identifiers for multiple identifiers" {
            $mockId1 = [guid]::NewGuid().ToString()
            $mockId2 = [guid]::NewGuid().ToString()
            $TokenName = "vstfs:///Classification/Node/$($mockId1):vstfs:///Classification/Node/$($mockId2)"
            $result = New-ACLToken -SecurityNamespace 'CSS' -TokenName $TokenName

            $result.type | Should -Be 'CSS'
            $result.Identifiers.Count | Should -Be 2
            $result.Identifiers[0].identifier | Should -Be $mockId1
            $result.Identifiers[1].identifier | Should -Be $mockId2
        }

    }

    Context 'Iteration Namespace' {

        It "Returns type as 'Unknown Iteration'" {
            $result =  New-ACLToken -SecurityNamespace 'Iteration' -TokenName 'bad-token'
            $result.type | Should -Be 'Unknown IterationPath'
        }

        It "Returns type as 'Iteration' and correct identifiers" {
            $mockId = [guid]::NewGuid().ToString()
            $TokenName = "vstfs:///Classification/Node/$mockId"
            $result = New-ACLToken -SecurityNamespace 'Iteration' -TokenName $TokenName

            $result.type | Should -Be 'Iteration'
            $result.Identifiers.identifier | Should -Be $mockId
        }

        It "Results the correct Identifiers for multiple identifiers" {
            $mockId1 = [guid]::NewGuid().ToString()
            $mockId2 = [guid]::NewGuid().ToString()
            $TokenName = "vstfs:///Classification/Node/$($mockId1):vstfs:///Classification/Node/$($mockId2)"
            $result = New-ACLToken -SecurityNamespace 'Iteration' -TokenName $TokenName

            $result.type | Should -Be 'Iteration'
            $result.Identifiers.Count | Should -Be 2
            $result.Identifiers[0].identifier | Should -Be $mockId1
            $result.Identifiers[1].identifier | Should -Be $mockId2
        }

    }

    Context 'WorkItemQueryFolders SecurityNamespace' {

        It 'Returns the project id for a project-root query token' {
            $projectId = [guid]::NewGuid().ToString()
            $result = New-ACLToken -SecurityNamespace 'WorkItemQueryFolders' -TokenName "`$/$projectId"

            $result.type | Should -Be 'Query'
            $result.ProjectId | Should -Be $projectId
            $result.Identifiers.Count | Should -Be 0
        }

        It 'Returns the folder id for a single-folder query token' {
            $projectId = [guid]::NewGuid().ToString()
            $folderId  = [guid]::NewGuid().ToString()
            $result = New-ACLToken -SecurityNamespace 'WorkItemQueryFolders' -TokenName "`$/$projectId/$folderId"

            $result.type | Should -Be 'Query'
            $result.ProjectId | Should -Be $projectId
            $result.Identifiers.Count | Should -Be 1
            $result.Identifiers[0].identifier | Should -Be $folderId
        }

        It 'Returns the full folder chain, in order, for a nested query token' {
            $projectId = [guid]::NewGuid().ToString()
            $folderId1 = [guid]::NewGuid().ToString()
            $folderId2 = [guid]::NewGuid().ToString()
            $result = New-ACLToken -SecurityNamespace 'WorkItemQueryFolders' -TokenName "`$/$projectId/$folderId1/$folderId2"

            $result.Identifiers.Count | Should -Be 2
            $result.Identifiers[0].identifier | Should -Be $folderId1
            $result.Identifiers[1].identifier | Should -Be $folderId2
        }

        It 'Does not mistake the project id for the first folder in the chain' {
            # The project id is a GUID too, so a naive extraction over the whole token would
            # read it as folder number one and shift the entire chain.
            $projectId = [guid]::NewGuid().ToString()
            $folderId  = [guid]::NewGuid().ToString()
            $result = New-ACLToken -SecurityNamespace 'WorkItemQueryFolders' -TokenName "`$/$projectId/$folderId"

            $result.Identifiers.identifier | Should -Not -Contain $projectId
        }

        It 'Round-trips a query token back to its original string' {
            # New-ACLToken and ConvertTo-FormattedToken have to agree: if they disagree, a
            # permission written by Set() would never match the ACL read back by Get() and the
            # resource would report drift forever.
            . (Get-FunctionItem 'ConvertTo-FormattedToken.ps1').FullName

            $projectId = [guid]::NewGuid().ToString()
            $folderId1 = [guid]::NewGuid().ToString()
            $folderId2 = [guid]::NewGuid().ToString()
            $original  = "`$/$projectId/$folderId1/$folderId2"

            $structured = New-ACLToken -SecurityNamespace 'WorkItemQueryFolders' -TokenName $original
            ConvertTo-FormattedToken -Token $structured | Should -Be $original
        }

        It 'Round-trips a project-root query token back to its original string' {
            . (Get-FunctionItem 'ConvertTo-FormattedToken.ps1').FullName

            $projectId = [guid]::NewGuid().ToString()
            $original  = "`$/$projectId"

            $structured = New-ACLToken -SecurityNamespace 'WorkItemQueryFolders' -TokenName $original
            ConvertTo-FormattedToken -Token $structured | Should -Be $original
        }

        It 'Returns QueryUnknown for a token that is not a query token' {
            $result = New-ACLToken -SecurityNamespace 'WorkItemQueryFolders' -TokenName 'not-a-query-token'
            $result.type | Should -Be 'QueryUnknown'
        }
    }

    Context 'Build SecurityNamespace - folder tokens' {

        BeforeAll {
            . (Get-FunctionItem 'Format-AzDoPipelineFolderPath.ps1').FullName
            Mock -CommandName Resolve-AzDoProjectIdForToken -MockWith { return 'project-id-1' }
        }

        It 'Treats a numeric tail as a pipeline definition' {
            $result = New-ACLToken -SecurityNamespace 'Build' -TokenName 'MyProject/123'
            $result.type | Should -Be 'Build'
        }

        It 'Treats an unmarked name as a pipeline, not a folder' {
            # A pipeline can legitimately be called 'Platform', so the bare form stays a pipeline.
            $result = New-ACLToken -SecurityNamespace 'Build' -TokenName 'MyProject/Platform'
            $result.type | Should -Be 'Build'
        }

        It 'Treats a path marked with a leading separator as a folder' {
            $result = New-ACLToken -SecurityNamespace 'Build' -TokenName 'MyProject/\Platform'
            $result.type | Should -Be 'BuildFolder'
            $result.FolderPath | Should -Be 'Platform'
        }

        It 'Handles a nested folder path' {
            $result = New-ACLToken -SecurityNamespace 'Build' -TokenName 'MyProject/\Platform\Release'
            $result.type | Should -Be 'BuildFolder'
            $result.FolderPath | Should -Be 'Platform\Release'
        }

        It 'Normalizes forward slashes in a folder path' {
            $result = New-ACLToken -SecurityNamespace 'Build' -TokenName 'MyProject/\Platform/Release'
            $result.FolderPath | Should -Be 'Platform\Release'
        }

        It 'Round-trips a folder token into the API token form' {
            . (Get-FunctionItem 'ConvertTo-FormattedToken.ps1').FullName

            $structured = New-ACLToken -SecurityNamespace 'Build' -TokenName 'MyProject/\Platform'
            # The API token carries the resolved project id and the path without its marker.
            ConvertTo-FormattedToken -Token $structured | Should -Be 'project-id-1/Platform'
        }
    }

    Context 'ReleaseManagement SecurityNamespace' {

        BeforeAll {
            . (Get-FunctionItem 'Format-AzDoPipelineFolderPath.ps1').FullName
            . (Get-FunctionItem 'ConvertTo-FormattedToken.ps1').FullName
            Mock -CommandName Resolve-AzDoProjectIdForToken -MockWith { return 'project-id-1' }
            Mock -CommandName Get-CacheItem -MockWith { return [PSCustomObject]@{ id = '456' } }
        }

        It 'Treats a bare project name as the project root' {
            $result = New-ACLToken -SecurityNamespace 'ReleaseManagement' -TokenName 'MyProject'
            $result.type | Should -Be 'ReleaseRoot'
            $result.ProjectId | Should -Be 'project-id-1'
        }

        It 'Round-trips a project-root token' {
            $structured = New-ACLToken -SecurityNamespace 'ReleaseManagement' -TokenName 'MyProject'
            ConvertTo-FormattedToken -Token $structured | Should -Be 'project-id-1'
        }

        It 'Treats a path marked with a leading separator as a folder' {
            $result = New-ACLToken -SecurityNamespace 'ReleaseManagement' -TokenName 'MyProject/\Platform'
            $result.type | Should -Be 'ReleaseFolder'
            $result.FolderPath | Should -Be 'Platform'
        }

        It 'Handles a nested folder path' {
            $result = New-ACLToken -SecurityNamespace 'ReleaseManagement' -TokenName 'MyProject/\Platform\Release'
            $result.type | Should -Be 'ReleaseFolder'
            $result.FolderPath | Should -Be 'Platform\Release'
        }

        It 'Round-trips a folder token into the API token form' {
            $structured = New-ACLToken -SecurityNamespace 'ReleaseManagement' -TokenName 'MyProject/\Platform'
            ConvertTo-FormattedToken -Token $structured | Should -Be 'project-id-1/Platform'
        }

        It 'Resolves a definition name at the root, marked with a leading @' {
            $result = New-ACLToken -SecurityNamespace 'ReleaseManagement' -TokenName 'MyProject/@MyRelease'
            $result.type | Should -Be 'ReleaseDefinition'
            $result.FolderPath | Should -BeNullOrEmpty
            $result.DefinitionId | Should -Be '456'
        }

        It 'Round-trips a root definition token into the API token form' {
            $structured = New-ACLToken -SecurityNamespace 'ReleaseManagement' -TokenName 'MyProject/@MyRelease'
            ConvertTo-FormattedToken -Token $structured | Should -Be 'project-id-1/456'
        }

        It 'Resolves a definition name inside a folder' {
            $result = New-ACLToken -SecurityNamespace 'ReleaseManagement' -TokenName 'MyProject/\Platform\@MyRelease'
            $result.type | Should -Be 'ReleaseDefinition'
            $result.FolderPath | Should -Be 'Platform'
            $result.DefinitionId | Should -Be '456'
        }

        It 'Round-trips a definition-in-folder token into the API token form, root folder omitted' {
            $structured = New-ACLToken -SecurityNamespace 'ReleaseManagement' -TokenName 'MyProject/\Platform\@MyRelease'
            ConvertTo-FormattedToken -Token $structured | Should -Be 'project-id-1/Platform/456'
        }

        It 'Falls back to the definition name when it is not cached' {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            $result = New-ACLToken -SecurityNamespace 'ReleaseManagement' -TokenName 'MyProject/@MyRelease'
            $result.DefinitionId | Should -Be 'MyRelease'
        }
    }

    Context 'Unknown SecurityNamespace' {

        It 'Should return Generic type for unrecognized security namespace (pass-through)' {
            $result = New-ACLToken -SecurityNamespace 'Unknown' -TokenName 'Any/Token'
            $result.type | Should -Be 'Generic'
            $result.TokenValue | Should -Be 'Any/Token'
        }
    }
}
