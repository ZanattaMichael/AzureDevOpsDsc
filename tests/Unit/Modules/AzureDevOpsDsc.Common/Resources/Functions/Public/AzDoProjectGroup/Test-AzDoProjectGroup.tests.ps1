$currentFile = $MyInvocation.MyCommand.Path

Describe 'Test-AzDoProjectGroup' -Tag "Unit", "ProjectGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Test-AzDoProjectGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Format-AzDoGroup has no source file; define a stub so Pester can mock it
        if (-not (Get-Command 'Format-AzDoGroup' -ErrorAction SilentlyContinue)) {
            function Format-AzDoGroup { param([string]$Prefix, [string]$GroupName) return "$Prefix\$GroupName" }
        }

        Mock -CommandName Get-CacheItem -MockWith {
            param ($Key, $Type)
            if ($Key -eq 'groupKey' -and $Type -eq 'LiveGroups') { return $true }
            return $false
        }
        Mock -CommandName Format-AzDoGroup -MockWith { return "groupKey" }
    }

    Context 'When parameters are valid' {
        It 'Should return true when group is found in cache' {
            $GetResult = @{
                Status  = [DSCGetSummaryState]::Unchanged
                Current = @{ description = 'Group Description' }
            }
            $result = Test-AzDoProjectGroup -GroupName 'TestGroup' -GetResult $GetResult
            $result | Should -BeTrue
        }

        It 'Should return true when status is Unchanged regardless of description match' {
            $GetResult = @{
                Status  = [DSCGetSummaryState]::Unchanged
                Current = @{ description = 'Same Description' }
            }
            $result = Test-AzDoProjectGroup -GroupName 'TestGroup' -GroupDescription 'Same Description' -GetResult $GetResult
            # Source always returns $true for Unchanged status (line 68: return $true)
            $result | Should -BeTrue
        }

        It 'Should return true when status is Changed and group present in both live and cache' {
            $GetResult = @{
                Status  = [DSCGetSummaryState]::Changed
                Current = @{}
                Cache   = @{}
            }
            $result = Test-AzDoProjectGroup -GroupName 'TestGroup' -GetResult $GetResult
            $result | Should -BeTrue
        }

        It 'Should return true when status is Changed and group present in live but not cache' {
            $GetResult = @{
                Status  = [DSCGetSummaryState]::Changed
                Current = @{}
                Cache   = $null
            }
            $result = Test-AzDoProjectGroup -GroupName 'TestGroup' -GetResult $GetResult
            $result | Should -BeTrue
        }

        It 'Should return true when status is Changed and group not present in live but in cache' {
            $GetResult = @{
                Status  = [DSCGetSummaryState]::Changed
                Current = $null
                Cache   = @{}
            }
            $result = Test-AzDoProjectGroup -GroupName 'TestGroup' -GetResult $GetResult
            $result | Should -BeTrue
        }

        It 'Should return false when status is Renamed' {
            $GetResult = @{ Status = [DSCGetSummaryState]::Renamed }
            $result = Test-AzDoProjectGroup -GroupName 'TestGroup' -GetResult $GetResult
            $result | Should -BeFalse
        }

        It 'Should return true when group present in cache (Missing status falls through to cache check)' {
            $GetResult = @{ Status = [DSCGetSummaryState]::Missing }
            $result = Test-AzDoProjectGroup -GroupName 'TestGroup' -GetResult $GetResult
            $result | Should -BeTrue
        }
    }
}
