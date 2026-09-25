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

        # GitBranch/GitTag defer the per-segment hex/UTF-16LE encoding to ConvertTo-GitRefToken.
        . (Get-FunctionItem 'ConvertTo-GitRefToken.ps1').FullName

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

    It "should format a GitBranch token, hex/UTF-16LE-encoding the branch name" {
        $token = @{
            type = 'GitBranch'
            projectId = 'myProject'
            RepoId = 'myRepo'
            BranchName = 'main'
        }

        $result = ConvertTo-FormattedToken -Token $token

        $result | Should -Be 'repoV2/myProject/myRepo/refs/heads/6d00610069006e00'
    }

    It "should format a GitBranch token with a multi-segment (branch folder) name" {
        $token = @{
            type = 'GitBranch'
            projectId = 'myProject'
            RepoId = 'myRepo'
            BranchName = 'release/1.0'
        }

        $result = ConvertTo-FormattedToken -Token $token

        # Each ref segment is encoded separately and rejoined with a literal slash.
        $result | Should -Match '^repoV2/myProject/myRepo/refs/heads/[0-9a-f]+/[0-9a-f]+$'
    }

    It "should format a GitTag token, hex/UTF-16LE-encoding the tag name" {
        $token = @{
            type = 'GitTag'
            projectId = 'myProject'
            RepoId = 'myRepo'
            TagName = 'v1.0'
        }

        $result = ConvertTo-FormattedToken -Token $token

        $result | Should -Be ('repoV2/myProject/myRepo/refs/tags/{0}' -f (ConvertTo-GitRefToken -RefName 'v1.0'))
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

    It "should format Tagging token correctly" {
        $token = @{
            type      = 'Tagging'
            ProjectId = 'myProject'
        }

        $result = ConvertTo-FormattedToken -Token $token

        $result | Should -Be '/myProject'
    }

    It "should format Analytics token correctly" {
        $token = @{
            type      = 'Analytics'
            ProjectId = 'myProject'
        }

        $result = ConvertTo-FormattedToken -Token $token

        $result | Should -Be '$/myProject'
    }

    It "should format AnalyticsViews token correctly" {
        $token = @{
            type      = 'AnalyticsViews'
            ProjectId = 'myProject'
        }

        $result = ConvertTo-FormattedToken -Token $token

        $result | Should -Be '$/Shared/myProject'
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
