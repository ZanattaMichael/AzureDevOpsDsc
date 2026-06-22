$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoProcess' -Tag "Unit", "Process" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoProcess.tests.ps1'
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
        Mock -CommandName New-DevOpsProcess -MockWith {
            return @{ typeId = 'new-process-id'; name = 'MyProcess'; description = 'A description' }
        }
    }

    Context 'when the parent process is found' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith { return @{ id = 'parent-id'; name = 'Agile' } }
        }

        It 'resolves the parent and calls New-DevOpsProcess with the parent type id' {
            New-AzDoProcess -ProcessName 'MyProcess' -ParentProcessName 'Agile' -Description 'A description'
            Assert-MockCalled -CommandName New-DevOpsProcess -Times 1 -ParameterFilter {
                $ParentProcessTypeId -eq 'parent-id' -and $Name -eq 'MyProcess'
            }
        }

        It 'adds the created process to the LiveProcesses cache' {
            New-AzDoProcess -ProcessName 'MyProcess' -ParentProcessName 'Agile' -Description 'A description'
            Assert-MockCalled -CommandName Add-CacheItem -Times 1 -ParameterFilter { $Type -eq 'LiveProcesses' }
        }
    }

    Context 'when the parent process is not found' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith { return $null }
        }

        It 'throws and does not call New-DevOpsProcess' {
            { New-AzDoProcess -ProcessName 'MyProcess' -ParentProcessName 'Nope' -Description 'x' } | Should -Throw
            Assert-MockCalled -CommandName New-DevOpsProcess -Times 0
        }
    }

    Context 'when no parent process name is supplied' {

        It 'throws' {
            { New-AzDoProcess -ProcessName 'MyProcess' -ParentProcessName '' -Description 'x' } | Should -Throw
        }
    }
}
