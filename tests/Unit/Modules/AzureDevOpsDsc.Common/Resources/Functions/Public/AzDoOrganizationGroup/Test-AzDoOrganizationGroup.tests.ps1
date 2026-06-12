$currentFile = $MyInvocation.MyCommand.Path

Describe "Test-AzDoOrganizationGroup" -Tag "Unit", "OrganizationGroup" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Test-AzDoOrganizationGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if (-not (Get-Command 'Format-AzDoGroup' -ErrorAction SilentlyContinue)) {
            function Format-AzDoGroup { param([string]$Prefix, [string]$GroupName) return "$Prefix\$GroupName" }
        }
        Mock -CommandName Format-AzDoGroup -MockWith { return 'groupKey' }
        Mock -CommandName Get-CacheItem -MockWith { return $true }
    }

    Context "when the group exists (Unchanged status)" {
        It "should return true" {
            $GetResult = @{
                Status  = [DSCGetSummaryState]::Unchanged
                Current = @{ description = 'SomeDescription' }
            }
            $result = Test-AzDoOrganizationGroup -GroupName 'ExistingGroup' -GetResult $GetResult
            $result | Should -Be $true
        }
    }

    Context "when the group has Renamed status" {
        It "should return false" {
            $GetResult = @{ Status = [DSCGetSummaryState]::Renamed }
            $result = Test-AzDoOrganizationGroup -GroupName 'ExistingGroup' -GetResult $GetResult
            $result | Should -Be $false
        }
    }

    Context "when GroupName is empty" {
        It "should throw a validation error" {
            { Test-AzDoOrganizationGroup -GroupName '' } | Should -Throw
        }
    }

    Context "when group is found in cache (Missing/other status)" {
        It "should return true when cache item exists" {
            Mock -CommandName Get-CacheItem -MockWith { return $true }
            $GetResult = @{ Status = [DSCGetSummaryState]::Missing }
            $result = Test-AzDoOrganizationGroup -GroupName 'ExistingGroup' -GetResult $GetResult
            $result | Should -BeTrue
        }

        It "should return false when cache item not found" {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            $GetResult = @{ Status = [DSCGetSummaryState]::Missing }
            $result = Test-AzDoOrganizationGroup -GroupName 'NonExistentGroup' -GetResult $GetResult
            $result | Should -BeFalse
        }
    }
}
