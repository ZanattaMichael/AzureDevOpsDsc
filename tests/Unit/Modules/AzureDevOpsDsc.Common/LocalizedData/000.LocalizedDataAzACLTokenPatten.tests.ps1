$currentFile = $MyInvocation.MyCommand.Path

# Define tests
Describe "Testing LocalizedDataAzACLTokenPattern regex patterns" -Tag "Unit", "LocalizedData" {

    BeforeAll {
        $source = Get-FunctionItem '000.LocalizedDataAzACLTokenPatten.ps1'

        . $source.FullName

    }

    It "OrganizationGit should match 'repoV2'" {
        'repoV2' -match $LocalizedDataAzACLTokenPatten.OrganizationGit | Should -BeTrue
    }

    It "GitProject should match 'repoV2/Project123'" {
        'repoV2/Project123' -match $LocalizedDataAzACLTokenPatten.GitProject | Should -BeTrue
    }

    It "GitRepository should match 'repoV2/Project123/Repo456'" {
        'repoV2/Project123/Repo456' -match $LocalizedDataAzACLTokenPatten.GitRepository | Should -BeTrue
    }

    It "GitBranch should match a hex/UTF-16LE-encoded branch segment (e.g. 'main')" {
        # Real branch names are hex/UTF-16LE-encoded on the wire - '6d00610069006e00' is 'main'.
        'repoV2/Project123/Repo456/refs/heads/6d00610069006e00' -match $LocalizedDataAzACLTokenPatten.GitBranch | Should -BeTrue
    }

    It "GitBranch should match a multi-segment (branch folder) encoded ref, e.g. 'release/1.0'" {
        # Only the hex-digit shape matters here - the round-trip through the real encoding is
        # covered by New-ACLToken.tests.ps1's Git Repositories round-trip Context.
        'repoV2/Project123/Repo456/refs/heads/72656c65617365/312e30' -match $LocalizedDataAzACLTokenPatten.GitBranch | Should -BeTrue
    }

    It "GitTag should match a hex/UTF-16LE-encoded tag segment (e.g. 'v1.0')" {
        'repoV2/Project123/Repo456/refs/tags/760031002e00300000' -match $LocalizedDataAzACLTokenPatten.GitTag | Should -BeTrue
    }

    It "GitBranch should not match an unencoded (non-hex) branch segment" {
        # Guards against regressing to the pre-fix behavior, which accepted any literal text here.
        'repoV2/Project123/Repo456/refs/heads/main' -match $LocalizedDataAzACLTokenPatten.GitBranch | Should -BeFalse
    }

    It "GroupPermission should match 'Project123\Group456'" {
        'Project123\Group456' -match $LocalizedDataAzACLTokenPatten.GroupPermission | Should -BeTrue
    }

    It "ResourcePermission should match 'Project123'" {
        'Project123' -match $LocalizedDataAzACLTokenPatten.ResourcePermission | Should -BeTrue
    }

    # Negative tests
    It "OrganizationGit should not match 'repoV3'" {
        'repoV3' -match $LocalizedDataAzACLTokenPatten.OrganizationGit | Should -BeFalse
    }

    It "GitProject should not match 'repoV2/'" {
        'repoV2/' -match $LocalizedDataAzACLTokenPatten.GitProject | Should -BeFalse
    }

    It "GitRepository should not match 'repoV2/Project123/'" {
        'repoV2/Project123/' -match $LocalizedDataAzACLTokenPatten.GitRepository | Should -BeFalse
    }

    It "GitBranch should not match 'repoV2/Project123/Repo456/branches/main'" {
        'repoV2/Project123/Repo456/branches/main' -match $LocalizedDataAzACLTokenPatten.GitBranch | Should -BeFalse
    }

    It "GroupPermission should not match 'Project123'" {
        'Project123' -match $LocalizedDataAzACLTokenPatten.GroupPermission | Should -BeFalse
    }

    It "ResourcePermission should not match 'Project123\Extra'" {
        'Project123\Extra' -match $LocalizedDataAzACLTokenPatten.ResourcePermission | Should -BeFalse
    }
}
