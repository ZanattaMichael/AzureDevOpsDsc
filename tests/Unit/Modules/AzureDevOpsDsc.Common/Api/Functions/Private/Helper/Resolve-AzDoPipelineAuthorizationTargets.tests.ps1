$currentFile = $MyInvocation.MyCommand.Path

Describe "Resolve-AzDoPipelineAuthorizationTargets" -Tag "Unit", "PipelineAuthorization" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Resolve-AzDoPipelineAuthorizationTargets.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # Real normalizer - the function under test relies on its exact behaviour.
        . (Get-FunctionItem 'Format-AzDoPipelineFolderPath.ps1').FullName

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the cache holds a match in the same folder" {
        It "resolves without a live lookup" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 101; name = 'deploy-infra'; folder = '\Platform' } }
            Mock -CommandName List-DevOpsPipelines

            $result = @(Resolve-AzDoPipelineAuthorizationTargets -ProjectName 'TestProject' -PipelinePaths @('\Platform\deploy-infra'))

            $result[0].Id | Should -Be 101
            $result[0].Path | Should -Be '\Platform\deploy-infra'
            Assert-MockCalled -CommandName List-DevOpsPipelines -Times 0
        }
    }

    Context "when the cache holds a same-named pipeline in a different folder" {
        It "does not accept the cached candidate and falls back to a live lookup" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 999; name = 'deploy-infra'; folder = '\Other' } }
            Mock -CommandName Add-CacheItem
            Mock -CommandName List-DevOpsPipelines -MockWith {
                return @(
                    @{ id = 999; name = 'deploy-infra'; folder = '\Other' },
                    @{ id = 202; name = 'deploy-infra'; folder = '\Platform' }
                )
            }

            $result = @(Resolve-AzDoPipelineAuthorizationTargets -ProjectName 'TestProject' -PipelinePaths @('\Platform\deploy-infra'))

            $result[0].Id | Should -Be 202
        }
    }

    Context "when a path cannot be resolved to any pipeline" {
        It "returns a `$null Id for that path rather than throwing or omitting it" {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsPipelines -MockWith { return @() }

            $result = @(Resolve-AzDoPipelineAuthorizationTargets -ProjectName 'TestProject' -PipelinePaths @('\Missing\pipeline'))

            $result[0].Id | Should -BeNullOrEmpty
            $result[0].Path | Should -Be '\Missing\pipeline'
        }
    }

    Context "when resolving several paths that all miss the cache" {
        It "fetches the live pipeline list only once" {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName Add-CacheItem
            Mock -CommandName List-DevOpsPipelines -MockWith {
                return @(
                    @{ id = 1; name = 'one'; folder = '\' },
                    @{ id = 2; name = 'two'; folder = '\' }
                )
            }

            $result = Resolve-AzDoPipelineAuthorizationTargets -ProjectName 'TestProject' -PipelinePaths @('one', 'two')

            $result[0].Id | Should -Be 1
            $result[1].Id | Should -Be 2
            Assert-MockCalled -CommandName List-DevOpsPipelines -Times 1
        }
    }

    Context "when a root pipeline is given without a leading separator" {
        It "matches it against the root folder" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 55; name = 'build'; folder = '\' } }

            $result = @(Resolve-AzDoPipelineAuthorizationTargets -ProjectName 'TestProject' -PipelinePaths @('build'))

            $result[0].Id | Should -Be 55
        }
    }
}
