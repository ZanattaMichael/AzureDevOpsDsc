$currentFile = $MyInvocation.MyCommand.Path

# ConvertTo-FormattedToken.Tests.ps1

Describe "ConvertTo-FormattedToken" -Tag "Unit", "ACL", "Helper" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'ConvertTo-FormattedToken.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

    }

    It "should format GitOrganization token correctly" {
        $token = @{
            type = 'GitOrganization'
        }

        $result = ConvertTo-FormattedToken -Token $token

        $result | Should -Be 'repoV2'
    }

    It "should format GitProject token correctly" {
        $token = @{
            type = 'GitProject'
            projectId = 'myProject'
        }

        $result = ConvertTo-FormattedToken -Token $token

        $result | Should -Be 'repoV2/myProject'
    }

    It "should format GitRepository token correctly" {
        $token = @{
            type = 'GitRepository'
            projectId = 'myProject'
            RepoId = 'myRepo'
        }

        $result = ConvertTo-FormattedToken -Token $token

        $result | Should -Be 'repoV2/myProject/myRepo'
    }

    It "should format a project-root query token" {
        $projectId = [guid]::NewGuid().ToString()
        $token = @{ type = 'Query'; ProjectId = $projectId; Identifiers = @() }

        ConvertTo-FormattedToken -Token $token | Should -Be "`$/$projectId"
    }

    it "should format a query token with a single folder" {
        $projectId = [guid]::NewGuid().ToString()
        $folderId  = [guid]::NewGuid().ToString()
        $token = @{ type = 'Query'; ProjectId = $projectId; Identifiers = @(@{ identifier = $folderId }) }

        ConvertTo-FormattedToken -Token $token | Should -Be "`$/$projectId/$folderId"
    }

    It "should format a query token with a nested folder chain, preserving order" {
        $projectId = [guid]::NewGuid().ToString()
        $folderId1 = [guid]::NewGuid().ToString()
        $folderId2 = [guid]::NewGuid().ToString()
        $token = @{
            type        = 'Query'
            ProjectId   = $projectId
            Identifiers = @(@{ identifier = $folderId1 }, @{ identifier = $folderId2 })
        }

        ConvertTo-FormattedToken -Token $token | Should -Be "`$/$projectId/$folderId1/$folderId2"
    }

    It "should return an empty string for unrecognized token type" {
        $token = @{
            type = 'UnknownType'
        }

        $result = ConvertTo-FormattedToken -Token $token

        $result | Should -Be ''
    }

    It "should return an empty string for an empty token" {
        $token = @{}

        $result = ConvertTo-FormattedToken -Token $token

        $result | Should -Be ''
    }
}
