$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsProcessAclToken' -Tag "Unit", "Process", "API" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsProcessAclToken.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Write-Warning
    }

    Context 'when scope is the AllProcesses sentinel' {

        It 'returns the org-wide root token' {
            $result = Get-DevOpsProcessAclToken -ProcessName 'AllProcesses' -OrganizationName 'myorg'
            $result | Should -Be '$PROCESS'
        }
    }

    Context 'when scope is a specific inherited process' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith { return @{ id = 'process-id'; name = 'MyProcess' } }
            Mock -CommandName Get-DevOpsProcess -MockWith { return @{ typeId = 'process-id'; parentProcessTypeId = 'parent-id' } }
        }

        It 'returns the per-process token $PROCESS:{parent}:{id}' {
            $result = Get-DevOpsProcessAclToken -ProcessName 'MyProcess' -OrganizationName 'myorg'
            $result | Should -Be '$PROCESS:parent-id:process-id'
        }
    }

    Context 'when scope is a system process (no parent)' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith { return @{ id = 'system-id'; name = 'Agile' } }
            Mock -CommandName Get-DevOpsProcess -MockWith { return @{ typeId = 'system-id'; parentProcessTypeId = '00000000-0000-0000-0000-000000000000' } }
        }

        It 'returns null and warns' {
            $result = Get-DevOpsProcessAclToken -ProcessName 'Agile' -OrganizationName 'myorg'
            $result | Should -BeNullOrEmpty
            Assert-MockCalled -CommandName Write-Warning -Times 1
        }
    }

    Context 'when the process does not exist' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith { return $null }
        }

        It 'returns null' {
            $result = Get-DevOpsProcessAclToken -ProcessName 'Missing' -OrganizationName 'myorg'
            $result | Should -BeNullOrEmpty
        }
    }
}
