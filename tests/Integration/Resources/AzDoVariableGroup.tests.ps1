Describe "AzDoVariableGroup Integration Tests" -Tag "Integration", "VariableGroup" {

    BeforeAll {

        $PROJECTNAME = 'TEST_VARIABLEGROUP'

        $parameters = @{
            Name       = 'AzDoVariableGroup'
            ModuleName = 'AzureDevOpsDscNative'
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

    Context "Managing a secret variable" {

        BeforeAll {
            # The live group, read back through the REST API rather than through the resource,
            # so what Azure DevOps actually stored is what gets asserted on.
            function Get-LiveVariableGroup
            {
                $uri  = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/variablegroups?groupName={2}&api-version=7.1-preview.2' -f (Resolve-TestOrg), $PROJECTNAME, 'TEST_VG'
                $list = Invoke-RestMethod -Uri $uri -Headers (Resolve-TestAuthHeader)
                return @($list.value | Where-Object { $_.name -eq 'TEST_VG' })[0]
            }

            $parameters.Method = 'Set'
            $parameters.property.Variables = @{
                MyVar1   = @{ value = 'UpdatedValue1'; isSecret = $false }
                MyVar2   = 'UpdatedValue2'
                NewVar3  = @{ value = 'Value3';        isSecret = $false }
                MySecret = @{ value = 'S3cret-Value!'; isSecret = $true }
            }
        }

        It "Should not throw when adding a secret variable" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should store the variable as secret, with no readable value" {
            $live = Get-LiveVariableGroup
            $live | Should -Not -BeNullOrEmpty
            [bool]$live.variables.MySecret.isSecret | Should -BeTrue
            $live.variables.MySecret.value | Should -BeNullOrEmpty
        }

        It "Should store the flat variable as a non-secret with its value" {
            $live = Get-LiveVariableGroup
            [bool]$live.variables.MyVar2.isSecret | Should -BeFalse
            $live.variables.MyVar2.value | Should -Be 'UpdatedValue2'
        }

        It "Should return True after creation (a secret does not cause perpetual drift)" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should return True when the secret is declared without a value" {
            $noValue = @{
                Name       = 'AzDoVariableGroup'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    ProjectName       = $PROJECTNAME
                    VariableGroupName = 'TEST_VG'
                    Variables         = @{
                        MyVar1   = 'UpdatedValue1'
                        MyVar2   = 'UpdatedValue2'
                        NewVar3  = 'Value3'
                        MySecret = @{ isSecret = $true }
                    }
                }
            }

            (Invoke-DscResource @noValue).InDesiredState | Should -BeTrue
        }

        It "Should report drift when the secret is configured as a non-secret" {
            $inClear = @{
                Name       = 'AzDoVariableGroup'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    ProjectName       = $PROJECTNAME
                    VariableGroupName = 'TEST_VG'
                    Variables         = @{
                        MyVar1   = 'UpdatedValue1'
                        MyVar2   = 'UpdatedValue2'
                        NewVar3  = 'Value3'
                        MySecret = 'S3cret-Value!'
                    }
                }
            }

            (Invoke-DscResource @inClear).InDesiredState | Should -BeFalse
        }

        It "Should report drift when a non-secret value changes, and converge on Set" {
            $parameters.property.Variables.MyVar2 = 'ChangedValue2'

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse

            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue

            $live = Get-LiveVariableGroup
            $live.variables.MyVar2.value | Should -Be 'ChangedValue2'
            [bool]$live.variables.MySecret.isSecret | Should -BeTrue
            $live.variables.MySecret.value | Should -BeNullOrEmpty
        }

        It "Should keep the variables when a Set manages only the description" {
            $descriptionOnly = @{
                Name       = 'AzDoVariableGroup'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Set'
                property   = @{
                    ProjectName       = $PROJECTNAME
                    VariableGroupName = 'TEST_VG'
                    Description       = 'Description-only update'
                }
            }

            { Invoke-DscResource @descriptionOnly } | Should -Not -Throw

            $live = Get-LiveVariableGroup
            $live.description | Should -Be 'Description-only update'
            @($live.variables.PSObject.Properties).Count | Should -Be 4
            [bool]$live.variables.MySecret.isSecret | Should -BeTrue
            $live.variables.MyVar2.value | Should -Be 'ChangedValue2'
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
