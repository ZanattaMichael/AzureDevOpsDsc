$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoBuildRetentionSettings' -Tag "Unit", "BuildRetentionSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoBuildRetentionSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-DevOpsBuildRetentionSettings -MockWith {
            return @{
                purgeRuns                    = @{ value = 30; min = 1; max = 60 }
                purgeArtifacts                = @{ value = 14; min = 1; max = 60 }
                purgePullRequestRuns         = @{ value = 10; min = 1; max = 30 }
                retainRunsPerProtectedBranch = @{ value = 3; min = 1; max = 50 }
            }
        }
    }

    It 'returns Unchanged when a managed setting matches live state' {
        $result = Get-AzDoBuildRetentionSettings -ProjectName 'MyProject' -DaysToKeepRuns 30
        $result.status | Should -Be 'Unchanged'
    }

    It 'returns Changed when a managed setting differs from live state' {
        $result = Get-AzDoBuildRetentionSettings -ProjectName 'MyProject' -DaysToKeepRuns 45
        $result.status | Should -Be 'Changed'
        $result.propertiesChanged | Should -Contain 'DaysToKeepRuns'
    }

    It 'ignores unmanaged settings (not bound)' {
        $result = Get-AzDoBuildRetentionSettings -ProjectName 'MyProject' -DaysToKeepRuns 30
        $result.propertiesChanged | Should -Not -Contain 'DaysToKeepArtifacts'
    }

    It 'reports the live value for every setting regardless of whether it is managed' {
        $result = Get-AzDoBuildRetentionSettings -ProjectName 'MyProject'
        $result.DaysToKeepRuns                 | Should -Be 30
        $result.DaysToKeepArtifacts            | Should -Be 14
        $result.DaysToKeepPullRequestRuns      | Should -Be 10
        $result.RunsToRetainPerProtectedBranch | Should -Be 3
    }

    Context 'when a managed value is outside the live min/max range' {

        It 'returns status Error and carries the range error, without reporting drift' {
            $result = Get-AzDoBuildRetentionSettings -ProjectName 'MyProject' -DaysToKeepRuns 999
            $result.status | Should -Be 'Error'
            $result.rangeErrors | Should -HaveCount 1
            $result.rangeErrors[0] | Should -BeLike "*DaysToKeepRuns*999*1-60*"
            $result.propertiesChanged | Should -BeNullOrEmpty
        }

        It 'names the property, the value and the allowed range' {
            $result = Get-AzDoBuildRetentionSettings -ProjectName 'MyProject' -RunsToRetainPerProtectedBranch 0
            $result.reason | Should -BeLike "*RunsToRetainPerProtectedBranch*0*1-50*"
        }
    }

    Context 'when the settings cannot be retrieved' {

        BeforeEach { Mock -CommandName Get-DevOpsBuildRetentionSettings -MockWith { return $null } }

        It 'returns status Error' {
            $result = Get-AzDoBuildRetentionSettings -ProjectName 'MyProject' -DaysToKeepRuns 30
            $result.status | Should -Be 'Error'
        }
    }
}
