$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoTaskGroup" -Tag "Unit", "TaskGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoTaskGroup.tests.ps1'
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
        Mock -CommandName New-DevOpsTaskGroup -MockWith { return $mockTaskGroup }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
    }

    Context "when mandatory parameters are provided" {

        It "calls New-DevOpsTaskGroup" {
            New-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName New-DevOpsTaskGroup -Exactly -Times 1
        }

        It "calls New-DevOpsTaskGroup with the correct ProjectName and TaskGroupName" {
            New-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName New-DevOpsTaskGroup -Exactly -Times 1 -ParameterFilter {
                $ProjectName -eq 'TestProject' -and $TaskGroupName -eq 'TestTaskGroup'
            }
        }

        It "calls Add-CacheItem with the correct key and type" {
            New-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestTaskGroup' -and $Type -eq 'LiveTaskGroups'
            }
        }

        It "calls Export-CacheObject for LiveTaskGroups" {
            New-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveTaskGroups'
            }
        }

        It "calls Refresh-CacheObject for LiveTaskGroups" {
            New-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveTaskGroups'
            }
        }
    }

    Context "when optional parameters are provided" {

        It "passes Description to New-DevOpsTaskGroup" {
            New-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup' -Description 'My Description'
            Assert-MockCalled -CommandName New-DevOpsTaskGroup -Exactly -Times 1 -ParameterFilter {
                $Description -eq 'My Description'
            }
        }

        It "passes Category to New-DevOpsTaskGroup" {
            New-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup' -Category 'Build'
            Assert-MockCalled -CommandName New-DevOpsTaskGroup -Exactly -Times 1 -ParameterFilter {
                $Category -eq 'Build'
            }
        }

        It "uses the feeds API URI based on the organization name" {
            New-AzDoTaskGroup -ProjectName 'TestProject' -TaskGroupName 'TestTaskGroup'
            Assert-MockCalled -CommandName New-DevOpsTaskGroup -Exactly -Times 1 -ParameterFilter {
                $ApiUri -eq 'https://dev.azure.com/TestOrganization/'
            }
        }
    }
}
