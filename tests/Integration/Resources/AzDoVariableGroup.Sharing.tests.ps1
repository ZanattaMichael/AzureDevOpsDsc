Describe "AzDoVariableGroup Sharing Integration Tests" -Tag "Integration", "VariableGroup" {

    BeforeAll {

        $PROJECTNAME  = 'TEST_VG_SHARE1'
        $PROJECTNAME2 = 'TEST_VG_SHARE2'
        $VGNAME       = 'TEST_VG_SHARED'
        $SHAREDNAME   = 'TEST_VG_SHARED_ALIAS'
        $GROUPNAME    = 'VGSharePermGroup'

        $ORG        = Resolve-TestOrg
        $AuthHeader = Resolve-TestAuthHeader

        function Get-TestVariableGroupsForProject
        {
            param([string]$ProjectName)
            Invoke-RestMethod -Uri "https://dev.azure.com/$ORG/$ProjectName/_apis/distributedtask/variablegroups?api-version=7.1" -Headers $AuthHeader
        }

        $parameters = @{
            Name       = 'AzDoVariableGroup'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName       = $PROJECTNAME
                VariableGroupName = $VGNAME
                Description       = 'Shared variable group test'
                Variables         = @{
                    SharedVar = @{ value = 'SharedValue'; isSecret = $false }
                }
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
        New-TestProject -ProjectName $PROJECTNAME2
        New-TestGroup   -ProjectName $PROJECTNAME -GroupName $GROUPNAME
    }

    Context "Creating the variable group unshared" {

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

        It "Should not be visible to the second project yet" {
            $groups = Get-TestVariableGroupsForProject -ProjectName $PROJECTNAME2
            ($groups.value | Where-Object { $_.name -eq $VGNAME -or $_.name -eq $SHAREDNAME }) | Should -BeNullOrEmpty
        }
    }

    Context "Sharing the variable group with the second project" {

        BeforeAll {
            $parameters.Method                       = 'Set'
            $parameters.property.SharedWithProjects   = @($PROJECTNAME2)
            $parameters.property.SharedNameOverrides  = @{ $PROJECTNAME2 = $SHAREDNAME }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after sharing" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should be visible under the second project with the overridden name" {
            $groups = Get-TestVariableGroupsForProject -ProjectName $PROJECTNAME2
            $shared = $groups.value | Where-Object { $_.name -eq $SHAREDNAME }
            $shared | Should -Not -BeNullOrEmpty
        }
    }

    Context "Setting permissions on the shared variable group from the owning project" {

        BeforeAll {
            $permParameters = @{
                Name       = 'AzDoVariableGroupPermission'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Set'
                property   = @{
                    ProjectName       = $PROJECTNAME
                    VariableGroupName = $VGNAME
                    GroupName         = "[$PROJECTNAME]\$GROUPNAME"
                    isInherited       = $false
                    Permissions       = @(
                        @{
                            Identity   = "[$PROJECTNAME]\$GROUPNAME"
                            Permission = @{
                                Use  = 'Allow'
                                View = 'Allow'
                            }
                        }
                    )
                }
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @permParameters } | Should -Not -Throw
        }

        It "Should still resolve the ACL token against the owning project while the group is shared" {
            $permParameters.Method = 'Test'
            $result = Invoke-DscResource @permParameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Unsharing the variable group from the second project" {

        BeforeAll {
            $parameters.Method                     = 'Set'
            $parameters.property.SharedWithProjects = @()
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after unsharing" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should no longer be visible under the second project" {
            $groups = Get-TestVariableGroupsForProject -ProjectName $PROJECTNAME2
            ($groups.value | Where-Object { $_.name -eq $SHAREDNAME -or $_.name -eq $VGNAME }) | Should -BeNullOrEmpty
        }
    }

    Context "Removing the variable group" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName       = $PROJECTNAME
                VariableGroupName = $VGNAME
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
