$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoTaskGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoTaskGroup.tests.ps1'
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
        Mock -CommandName Set-DevOpsTaskGroup -MockWith { return $mockTaskGroup }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
    }

    Context "when the task group exists in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestTaskGroup' -and $Type -eq 'LiveTaskGroups'
            } -MockWith { return $mockTaskGroup }
        }

        It "calls Set-DevOpsTaskGroup" {
            Set-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Set-DevOpsTaskGroup -Exactly -Times 1
        }

        It "calls Set-DevOpsTaskGroup with the correct TaskGroupId" {
            Set-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Set-DevOpsTaskGroup -Exactly -Times 1 -ParameterFilter {
                $TaskGroupId -eq 'tg-id-001'
            }
        }

        It "calls Set-DevOpsTaskGroup with the correct ProjectName and TaskGroupName" {
            Set-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Set-DevOpsTaskGroup -Exactly -Times 1 -ParameterFilter {
                $ProjectName -eq 'TestProject' -and $TaskGroupName -eq 'TestTaskGroup'
            }
        }

        It "calls Add-CacheItem after updating" {
            Set-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestTaskGroup' -and $Type -eq 'LiveTaskGroups'
            }
        }

        It "calls Export-CacheObject for LiveTaskGroups" {
            Set-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveTaskGroups'
            }
        }

        It "calls Refresh-CacheObject for LiveTaskGroups" {
            Set-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveTaskGroups'
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

        It "writes an error and does not call Set-DevOpsTaskGroup" {
            Set-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'NonExistentGroup'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName Set-DevOpsTaskGroup -Exactly -Times 0
        }

        It "does not call Add-CacheItem" {
            Set-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'NonExistentGroup'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 0
        }
    }
}
