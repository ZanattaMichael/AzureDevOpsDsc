$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoProcess' -Tag "Unit", "Process" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoProcess.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Update-DevOpsProcess
    }

    Context 'when the process exists' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith {
                return [PSCustomObject]@{ id = 'mock-process-id'; name = 'MyProcess'; description = 'old' }
            }
        }

        It 'calls Update-DevOpsProcess with the resolved process id' {
            Set-AzDoProcess -ProcessName 'MyProcess' -ParentProcessName 'Agile' -Description 'new'
            Assert-MockCalled -CommandName Update-DevOpsProcess -Times 1 -ParameterFilter {
                $ProcessTypeId -eq 'mock-process-id' -and $Description -eq 'new'
            }
        }

        It 'refreshes the cache entry' {
            Set-AzDoProcess -ProcessName 'MyProcess' -ParentProcessName 'Agile' -Description 'new'
            Assert-MockCalled -CommandName Add-CacheItem -Times 1 -ParameterFilter { $Type -eq 'LiveProcesses' }
        }
    }

    Context 'when the process does not exist' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith { return $null }
        }

        It 'throws and does not call Update-DevOpsProcess' {
            { Set-AzDoProcess -ProcessName 'Missing' -ParentProcessName 'Agile' -Description 'x' } | Should -Throw
            Assert-MockCalled -CommandName Update-DevOpsProcess -Times 0
        }
    }
}
