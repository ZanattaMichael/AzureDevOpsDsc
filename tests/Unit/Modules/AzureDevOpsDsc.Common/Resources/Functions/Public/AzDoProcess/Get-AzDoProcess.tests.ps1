$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoProcess' -Tag "Unit", "Process" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoProcess.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context 'when the process exists' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith {
                return @{ id = 'mock-process-id'; name = 'MyProcess'; description = 'ExistingDescription' }
            }
        }

        It 'returns Unchanged when the description matches' {
            $result = Get-AzDoProcess -ProcessName 'MyProcess' -ParentProcessName 'Agile' -Description 'ExistingDescription'
            $result.status | Should -Be 'Unchanged'
            $result.ProcessName | Should -Be 'MyProcess'
        }

        It 'returns Changed when the description differs' {
            $result = Get-AzDoProcess -ProcessName 'MyProcess' -ParentProcessName 'Agile' -Description 'NewDescription'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Description'
        }
    }

    Context 'when the process does not exist' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith { return $null }
        }

        It 'returns status NotFound' {
            $result = Get-AzDoProcess -ProcessName 'Missing' -ParentProcessName 'Agile' -Description 'whatever'
            $result.status | Should -Be 'NotFound'
        }
    }
}
