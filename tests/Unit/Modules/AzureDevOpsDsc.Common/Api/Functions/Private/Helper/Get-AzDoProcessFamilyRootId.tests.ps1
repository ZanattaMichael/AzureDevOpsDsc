$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoProcessFamilyRootId" -Tag "Unit", "Project", "Process" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoProcessFamilyRootId.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }
    }

    Context "When the process detail is null" {
        It "should return null" {
            Get-AzDoProcessFamilyRootId -ProcessDetail $null | Should -BeNullOrEmpty
        }
    }

    Context "When the process is a system process" {
        It "should return its own typeId when customizationType is 'system'" {
            $detail = @{
                typeId             = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
                parentProcessTypeId = $null
                customizationType  = 'system'
            }

            Get-AzDoProcessFamilyRootId -ProcessDetail $detail | Should -Be 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        }

        It "should return its own typeId when parentProcessTypeId is empty" {
            $detail = @{
                typeId             = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
                parentProcessTypeId = ''
                customizationType  = 'system'
            }

            Get-AzDoProcessFamilyRootId -ProcessDetail $detail | Should -Be 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
        }

        It "should return its own typeId when parentProcessTypeId is the all-zero GUID" {
            $detail = @{
                typeId             = 'cccccccc-cccc-cccc-cccc-cccccccccccc'
                parentProcessTypeId = '00000000-0000-0000-0000-000000000000'
                customizationType  = 'system'
            }

            Get-AzDoProcessFamilyRootId -ProcessDetail $detail | Should -Be 'cccccccc-cccc-cccc-cccc-cccccccccccc'
        }
    }

    Context "When the process is an inherited process" {
        It "should return its parentProcessTypeId" {
            $detail = @{
                typeId             = 'dddddddd-dddd-dddd-dddd-dddddddddddd'
                parentProcessTypeId = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'
                customizationType  = 'inherited'
            }

            Get-AzDoProcessFamilyRootId -ProcessDetail $detail | Should -Be 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'
        }
    }

    Context "When comparing two inherited processes from the same parent" {
        It "should resolve to the same family root" {
            $detailA = @{ typeId = '1'; parentProcessTypeId = 'parent-1'; customizationType = 'inherited' }
            $detailB = @{ typeId = '2'; parentProcessTypeId = 'parent-1'; customizationType = 'inherited' }

            (Get-AzDoProcessFamilyRootId -ProcessDetail $detailA) | Should -Be (Get-AzDoProcessFamilyRootId -ProcessDetail $detailB)
        }
    }

    Context "When comparing two inherited processes from different parents" {
        It "should resolve to different family roots" {
            $detailA = @{ typeId = '1'; parentProcessTypeId = 'parent-1'; customizationType = 'inherited' }
            $detailB = @{ typeId = '2'; parentProcessTypeId = 'parent-2'; customizationType = 'inherited' }

            (Get-AzDoProcessFamilyRootId -ProcessDetail $detailA) | Should -Not -Be (Get-AzDoProcessFamilyRootId -ProcessDetail $detailB)
        }
    }
}
