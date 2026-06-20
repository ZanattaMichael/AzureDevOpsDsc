$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-AzDoProcess' -Tag "Unit", "Process" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoProcess.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsProcess
        Mock -CommandName Remove-CacheItem
    }

    Context 'when the process exists' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith { return @{ id = 'mock-process-id'; name = 'MyProcess' } }
        }

        It 'calls Remove-DevOpsProcess with the resolved process id' {
            Remove-AzDoProcess -ProcessName 'MyProcess' -ParentProcessName 'Agile'
            Assert-MockCalled -CommandName Remove-DevOpsProcess -Times 1 -ParameterFilter { $ProcessTypeId -eq 'mock-process-id' }
        }

        It 'removes the process from the cache' {
            Remove-AzDoProcess -ProcessName 'MyProcess' -ParentProcessName 'Agile'
            Assert-MockCalled -CommandName Remove-CacheItem -Times 1 -ParameterFilter { $Type -eq 'LiveProcesses' }
        }
    }

    Context 'when the process does not exist' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith { return $null }
        }

        It 'is a no-op and does not call Remove-DevOpsProcess' {
            Remove-AzDoProcess -ProcessName 'Missing' -ParentProcessName 'Agile'
            Assert-MockCalled -CommandName Remove-DevOpsProcess -Times 0
        }
    }
}
