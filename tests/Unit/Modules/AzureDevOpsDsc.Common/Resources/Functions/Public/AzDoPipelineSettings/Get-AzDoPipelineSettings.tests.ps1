$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoPipelineSettings' -Tag "Unit", "PipelineSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoPipelineSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-DevOpsPipelineSettings -MockWith {
            return @{ enforceJobAuthScope = $true; statusBadgesArePrivate = $false; enforceSettableVar = $true }
        }
    }

    It 'returns Unchanged when a specified setting matches live state' {
        $result = Get-AzDoPipelineSettings -ProjectName 'MyProject' -EnforceJobAuthScope $true
        $result.status | Should -Be 'Unchanged'
    }

    It 'returns Changed when a specified setting differs from live state' {
        $result = Get-AzDoPipelineSettings -ProjectName 'MyProject' -StatusBadgesArePrivate $true
        $result.status | Should -Be 'Changed'
        $result.propertiesChanged | Should -Contain 'StatusBadgesArePrivate'
    }

    It 'ignores settings that were not specified' {
        $result = Get-AzDoPipelineSettings -ProjectName 'MyProject' -EnforceJobAuthScope $true
        $result.propertiesChanged | Should -Not -Contain 'StatusBadgesArePrivate'
    }

    Context 'when the settings cannot be retrieved' {

        BeforeEach { Mock -CommandName Get-DevOpsPipelineSettings -MockWith { return $null } }

        It 'returns status Error' {
            $result = Get-AzDoPipelineSettings -ProjectName 'MyProject' -EnforceJobAuthScope $true
            $result.status | Should -Be 'Error'
        }
    }
}
