$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoGitPermission' -Tag "Unit", "GitPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoGitPermission.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load the summary state
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-ClassFilePath '002.LocalizedDataAzSerializationPatten')
        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-CacheItem -MockWith { return @{ namespaceId = '12345'; id = '67890' } }
        Mock -CommandName ConvertTo-ACLHashtable -MockWith { return @{} }
        Mock -CommandName Set-AzDoPermission -MockWith { }
    }

    Context 'With mandatory parameters provided' {
        It 'should call Get-CacheItem for SecurityNamespace and Project' {
            $params = @{
                ProjectName = 'TestProject'
                RepositoryName = 'TestRepo'
                isInherited = $true
            }
            New-AzDoGitPermission @params

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly 1
        }

        It 'should call ConvertTo-ACLHashtable and Set-AzDoPermission' {
            $params = @{
                ProjectName = 'TestProject'
                RepositoryName = 'TestRepo'
                isInherited = $true
                LookupResult = @{ propertiesChanged = @{} }
            }
            New-AzDoGitPermission @params

            Assert-MockCalled -CommandName ConvertTo-ACLHashtable -Exactly 1
            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly 1
        }
    }

    Context 'With all parameters provided' {
        It 'should set permissions correctly' {
            $permissions = @(@{ Permission = 'Read'; Access = 'Allow' })

            $params = @{
                ProjectName = 'TestProject'
                RepositoryName = 'TestRepo'
                isInherited = $true
                Permissions = $permissions
                LookupResult = @{ propertiesChanged = @{} }
                Ensure = 'Present'
                Force = $true
            }
            New-AzDoGitPermission @params

            Assert-MockCalled -CommandName Get-CacheItem -Times 2
            Assert-MockCalled -CommandName ConvertTo-ACLHashtable -Exactly 1
            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly 1
        }
    }

    Context 'When Get-CacheItem returns nothing' {
        It 'should not call ConvertTo-ACLHashtable or Set-AzDoPermission' {

            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'SecurityNamespaces' } -MockWith { return $null }
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveProjects' } -MockWith { return $null }
            Mock -CommandName Write-Warning -Verifiable

            $params = @{
                ProjectName = 'TestProject'
                RepositoryName = 'TestRepo'
                isInherited = $true
            }
            New-AzDoGitPermission @params

            Assert-MockCalled -CommandName ConvertTo-ACLHashtable -Exactly 0
            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly 0
            Assert-VerifiableMock
        }
    }

    # Not in use
    Context 'When Force switch is provided' -skip {
        It 'should handle the Force switch correctly' {
            $params = @{
                ProjectName = 'TestProject'
                RepositoryName = 'TestRepo'
                isInherited = $true
                Force = $true
            }
            New-AzDoGitPermission @params

            # Verify if any additional logic related to -Force was executed
            # This is a placeholder as the current implementation does not use -Force
        }
    }

    Context 'Verbose output' {
        It 'should write verbose output' {

            Mock -CommandName Write-Verbose -Verifiable

            $params = @{
                ProjectName = 'TestProject'
                RepositoryName = 'TestRepo'
                isInherited = $true
            }

            New-AzDoGitPermission @params

            Assert-VerifiableMock

        }
    }

    Context 'Branch and Tag scoped permissions' {

        BeforeAll {
            . (Get-FunctionItem 'Format-AzDoGitRefName.ps1').FullName
            . (Get-FunctionItem 'ConvertTo-GitRefToken.ps1').FullName
        }

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ namespaceId = '12345'; id = '67890' } }
        }

        It 'Stops without calling Set-AzDoPermission when BranchName and TagName are both specified' {

            Mock -CommandName Write-Warning -Verifiable

            $params = @{
                ProjectName = 'TestProject'
                RepositoryName = 'TestRepo'
                isInherited = $true
                BranchName = 'main'
                TagName = 'v1.0'
            }
            New-AzDoGitPermission @params

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly 0
            Assert-VerifiableMock
        }

        It 'Builds a branch-scoped DescriptorMatchToken using the hex/UTF-16LE-encoded branch name' {

            $script:capturedToken = $null
            Mock -CommandName ConvertTo-ACLHashtable -MockWith {
                $script:capturedToken = $DescriptorMatchToken
                return @{}
            }

            $params = @{
                ProjectName = 'TestProject'
                RepositoryName = 'TestRepo'
                isInherited = $true
                BranchName = 'main'
            }
            New-AzDoGitPermission @params

            $expected = '^repoV2\/[A-Za-z0-9-]+\/67890\/refs\/heads\/6d00610069006e00$'
            $script:capturedToken | Should -Be $expected
        }

        It 'Builds a tag-scoped DescriptorMatchToken using the hex/UTF-16LE-encoded tag name' {

            $script:capturedToken = $null
            Mock -CommandName ConvertTo-ACLHashtable -MockWith {
                $script:capturedToken = $DescriptorMatchToken
                return @{}
            }

            $params = @{
                ProjectName = 'TestProject'
                RepositoryName = 'TestRepo'
                isInherited = $true
                TagName = 'v1.0'
            }
            New-AzDoGitPermission @params

            $expected = '^repoV2\/[A-Za-z0-9-]+\/67890\/refs\/tags\/{0}$' -f (ConvertTo-GitRefToken -RefName 'v1.0')
            $script:capturedToken | Should -Be $expected
        }

        It 'Strips a leading refs/heads/ prefix from BranchName before building the token' {

            $script:capturedToken = $null
            Mock -CommandName ConvertTo-ACLHashtable -MockWith {
                $script:capturedToken = $DescriptorMatchToken
                return @{}
            }

            $params = @{
                ProjectName = 'TestProject'
                RepositoryName = 'TestRepo'
                isInherited = $true
                BranchName = 'refs/heads/main'
            }
            New-AzDoGitPermission @params

            $expected = '^repoV2\/[A-Za-z0-9-]+\/67890\/refs\/heads\/6d00610069006e00$'
            $script:capturedToken | Should -Be $expected
        }
    }
}
