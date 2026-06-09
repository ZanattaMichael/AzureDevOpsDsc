$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoTaskGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoTaskGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        $mockTaskGroup = @{
            id          = 'tg-id-001'
            name        = 'TestTaskGroup'
            description = 'A test task group'
        }

        Mock -CommandName Write-Verbose
    }

    Context "when the task group is found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTaskGroup' -and $Type -eq 'LiveTaskGroups'
            } -MockWith { return $mockTaskGroup }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            $result.status | Should -Be 'Unchanged'
        }

        It "populates liveCache with the cached task group object" {
            $result = Get-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            $result.liveCache | Should -Not -BeNullOrEmpty
            $result.liveCache.id | Should -Be 'tg-id-001'
        }

        It "calls Get-CacheItem with the correct key and type" {
            Get-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Get-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestTaskGroup' -and $Type -eq 'LiveTaskGroups'
            }
        }

        It "returns Ensure Absent in the result" {
            $result = Get-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            $result.Ensure | Should -Be 'Absent'
        }
    }

    Context "when the task group is not found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $true } -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'NonExistentGroup'
            $result.status | Should -Be 'NotFound'
        }

        It "does not populate liveCache" {
            $result = Get-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'NonExistentGroup'
            $result.liveCache | Should -BeNullOrEmpty
        }

        It "returns Ensure Absent in the result" {
            $result = Get-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'NonExistentGroup'
            $result.Ensure | Should -Be 'Absent'
        }
    }
}
