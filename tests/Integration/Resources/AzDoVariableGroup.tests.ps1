Describe "AzDoVariableGroup Integration Tests" -Tag "Integration", "VariableGroup" {

    BeforeAll {

        $PROJECTNAME = 'TEST_VARIABLEGROUP'

        $parameters = @{
            Name       = 'AzDoVariableGroup'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName       = $PROJECTNAME
                VariableGroupName = 'TEST_VG'
                Description       = 'Test variable group'
                Variables         = @{
                    MyVar1 = @{ value = 'Value1'; isSecret = $false }
                    MyVar2 = @{ value = 'Value2'; isSecret = $false }
                }
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
    }

    Context "Testing if the variable group exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (variable group does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the variable group" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creation" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the variable group" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Description = 'Updated test variable group'
            $parameters.property.Variables = @{
                MyVar1   = @{ value = 'UpdatedValue1'; isSecret = $false }
                MyVar2   = @{ value = 'UpdatedValue2'; isSecret = $false }
                NewVar3  = @{ value = 'Value3';        isSecret = $false }
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after update" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the variable group" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName       = $PROJECTNAME
                VariableGroupName = 'TEST_VG'
                Ensure            = 'Absent'
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Absent is desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
