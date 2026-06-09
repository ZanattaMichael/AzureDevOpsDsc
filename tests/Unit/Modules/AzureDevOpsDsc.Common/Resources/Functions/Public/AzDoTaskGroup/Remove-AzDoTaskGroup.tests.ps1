$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoTaskGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoTaskGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        $mockTaskGroup = @{
            id   = 'tg-id-001'
            name = 'TestTaskGroup'
        }

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsTaskGroup
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
    }

    Context "when the task group exists in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTaskGroup' -and $Type -eq 'LiveTaskGroups'
            } -MockWith { return $mockTaskGroup }
        }

        It "calls Remove-DevOpsTaskGroup" {
            Remove-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Remove-DevOpsTaskGroup -Exactly -Times 1
        }

        It "calls Remove-DevOpsTaskGroup with the correct TaskGroupId" {
            Remove-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Remove-DevOpsTaskGroup -Exactly -Times 1 -ParameterFilter {
                $TaskGroupId -eq 'tg-id-001'
            }
        }

        It "calls Remove-CacheItem with the correct key and type" {
            Remove-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestTaskGroup' -and $Type -eq 'LiveTaskGroups'
            }
        }

        It "calls Export-CacheObject for LiveTaskGroups" {
            Remove-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveTaskGroups'
            }
        }

        It "calls Get-CacheItem with the correct key and type" {
            Remove-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Get-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestTaskGroup' -and $Type -eq 'LiveTaskGroups'
            }
        }
    }

    Context "when the task group is not found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Type -eq 'LiveTaskGroups'
            } -MockWith { return $null }
            Mock -CommandName Write-Error -Verifiable
        }

        It "writes an error and does not call Remove-DevOpsTaskGroup" {
            Remove-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'NonExistentGroup'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName Remove-DevOpsTaskGroup -Exactly -Times 0
        }

        It "does not call Remove-CacheItem" {
            Remove-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'NonExistentGroup'
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly -Times 0
        }
    }
}
