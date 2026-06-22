$currentFile = $MyInvocation.MyCommand.Path

Describe 'Resolve-DevOpsProcess' -Tag "Unit", "Process", "API" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Resolve-DevOpsProcess.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Add-CacheItem
    }

    Context 'when the process is in the cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'cached-id'; name = 'Agile' } }
            Mock -CommandName List-DevOpsProcess
        }

        It 'returns the cached process without a live lookup' {
            $result = Resolve-DevOpsProcess -ProcessName 'Agile' -OrganizationName 'myorg'
            $result.id | Should -Be 'cached-id'
            Assert-MockCalled -CommandName List-DevOpsProcess -Times 0
        }
    }

    Context 'when the process is not cached but exists live' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsProcess -MockWith {
                return @(
                    @{ id = 'live-id'; name = 'MyProcess' }
                    @{ id = 'other-id'; name = 'Other' }
                )
            }
        }

        It 'returns the live process and caches it' {
            $result = Resolve-DevOpsProcess -ProcessName 'MyProcess' -OrganizationName 'myorg'
            $result.id | Should -Be 'live-id'
            Assert-MockCalled -CommandName Add-CacheItem -Times 1 -ParameterFilter { $Type -eq 'LiveProcesses' }
        }
    }

    Context 'when the process does not exist' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsProcess -MockWith { return @() }
        }

        It 'returns null' {
            $result = Resolve-DevOpsProcess -ProcessName 'Missing' -OrganizationName 'myorg'
            $result | Should -BeNullOrEmpty
        }
    }
}
