$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-ACLToken Function Tests' -Tags "Unit", "ACL", "Helper" {

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

    Context 'Unknown SecurityNamespace' {

        It 'Should return UnknownSecurityNamespace type for unrecognized security namespace' {
            $result = New-ACLToken -SecurityNamespace 'Unknown' -TokenName 'Any/Token'
            $result.type | Should -Be 'UnknownSecurityNamespace'
        }
    }
}
