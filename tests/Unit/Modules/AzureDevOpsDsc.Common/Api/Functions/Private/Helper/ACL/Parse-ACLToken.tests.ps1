$currentFile = $MyInvocation.MyCommand.Path

Describe 'Parse-ACLToken' -Tags "Unit", "ACL", "Helper" {

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

    It 'Should throw for unrecognized Identity token' {
        $token = "unknown:test"
        $SecurityNamespace = "Identity"
        { Parse-ACLToken -Token $token -SecurityNamespace $SecurityNamespace } | Should -Throw "Token '$token' is not recognized."
    }
}
