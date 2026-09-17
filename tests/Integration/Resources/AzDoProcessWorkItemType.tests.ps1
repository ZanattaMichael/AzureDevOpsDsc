Describe "AzDoProcessWorkItemType Integration Tests" -Tag "Integration", "Process" {

    BeforeAll {

        $PROCESSNAME = 'DSC_TEST_PROCESS_WIT'
        $WITNAME     = 'DscTestIncident'

        $processParameters = @{
            Name       = 'AzDoProcess'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProcessName       = $PROCESSNAME
                ParentProcessName = 'Agile'
                Description       = 'DSC integration test process'
            }
        }

        $parameters = @{
            Name       = 'AzDoProcessWorkItemType'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProcessName      = $PROCESSNAME
                WorkItemTypeName = $WITNAME
                Description      = 'DSC integration test work item type'
                Color            = 'F6546A'
                Icon             = 'icon_flame'
            }
        }

        # Work item types can only be added to an inherited process.
        Invoke-DscResource @processParameters
    }

    Context "Refusing to customize a system process" {

        It "Should report that a system process cannot be customized" {
            $systemParameters = @{
                Name       = 'AzDoProcessWorkItemType'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    ProcessName      = 'Agile'
                    WorkItemTypeName = 'Bug'
                    Description      = 'should never be applied'
                }
            }

            # Test() returns false rather than throwing, and no change is ever attempted.
            (Invoke-DscResource @systemParameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Testing if the work item type exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the work item type" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (work item type does not exist yet)" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the work item type" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when creating the work item type" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the work item type" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should remain in the desired state when tested repeatedly" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Accepting a colour written with a leading hash" {

        It "Should treat '#F6546A' and 'F6546A' as the same colour" {
            $hashParameters = @{
                Name       = 'AzDoProcessWorkItemType'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    ProcessName      = $PROCESSNAME
                    WorkItemTypeName = $WITNAME
                    Description      = 'DSC integration test work item type'
                    Color            = '#F6546A'
                    Icon             = 'icon_flame'
                }
            }

            (Invoke-DscResource @hashParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Refusing a destructive removal without consent" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProcessName            = $PROCESSNAME
                WorkItemTypeName       = $WITNAME
                AllowDestructiveRemove = $false
                Ensure                 = 'Absent'
            }
        }

        It "Should leave the work item type in place" {
            try { Invoke-DscResource @parameters } catch { }

            $checkParameters = @{
                Name       = 'AzDoProcessWorkItemType'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Get'
                property   = @{
                    ProcessName      = $PROCESSNAME
                    WorkItemTypeName = $WITNAME
                }
            }

            (Invoke-DscResource @checkParameters).Ensure | Should -Be 'Present'
        }
    }

    Context "Removing the work item type" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProcessName            = $PROCESSNAME
                WorkItemTypeName       = $WITNAME
                AllowDestructiveRemove = $true
                Ensure                 = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the work item type" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }
}
