Describe "AzDoGitPermission Integration Tests" -Tag "Integration", "GitPermission" {

    BeforeAll {

        $PROJECTNAME = 'TESTPROJECT_GIT_PERMISSION'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        function New-Repository { param([string]$ProjectName, [string]$RepositoryName)
            $null = Invoke-DscResource -Name 'AzDoGitRepository' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName    = $ProjectName
                RepositoryName = $RepositoryName
            }
        }

        function New-Group { param([string]$ProjectName, [string]$GroupName)
            $null = Invoke-DscResource -Name 'AzDoProjectGroup' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName = $ProjectName
                GroupName   = $GroupName
            }
        }

        $parameters = @{
            Name = 'AzDoGitPermission'
            ModuleName = 'AzureDevOpsDsc'
            property = @{
                ProjectName = $PROJECTNAME
                RepositoryName = 'TESTREPOSITORY'
                isInherited = $false
                Permissions = @(
                    @{
                        Identity = "[$PROJECTNAME]\Group1"
                        Permission = @{
                            GenericRead        = 'Allow'
                            GenericContribute  = 'Allow'
                        }
                    }
                    @{
                        Identity = "[$PROJECTNAME]\Group2"
                        Permission = @{
                            GenericRead        = 'Deny'
                            GenericContribute  = 'Deny'
                        }
                    }
                )
            }
        }

        New-Project $PROJECTNAME
        New-Repository -ProjectName $PROJECTNAME -RepositoryName 'TESTREPOSITORY'
        'Group1', 'Group2' | ForEach-Object { New-Group -ProjectName $PROJECTNAME -GroupName $_ }
    }

    Context "Testing if the permissions exist" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }

    }

    Context "Creating new permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

    }

    Context "Changing permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity = "[$PROJECTNAME]\Group1"
                    Permission = @{
                        GenericRead        = 'Allow'
                        GenericContribute  = 'Deny'
                    }
                }
                @{
                    Identity = "[$PROJECTNAME]\Group2"
                    Permission = @{
                        GenericRead        = 'Deny'
                        GenericContribute  = 'Allow'
                    }
                }
            )
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Clearing permissions should revert to inherited" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @()
            $parameters.property.isInherited = $true
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

}
