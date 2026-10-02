Describe "AzDoServiceConnection Sharing Integration Tests" -Tag "Integration", "ServiceConnection" {

    BeforeAll {

        $PROJECTNAME  = 'TEST_SC_SHARE1'
        $PROJECTNAME2 = 'TEST_SC_SHARE2'
        $SCNAME       = 'TEST_SC_SHARED'
        $SHAREDNAME   = 'TEST_SC_SHARED_ALIAS'
        $GROUPNAME    = 'SCSharePermGroup'

        $ORG        = Resolve-TestOrg
        $AuthHeader = Resolve-TestAuthHeader

        function Get-TestServiceConnectionsForProject
        {
            param([string]$ProjectName)
            Invoke-RestMethod -Uri "https://dev.azure.com/$ORG/$ProjectName/_apis/serviceendpoint/endpoints?api-version=7.1-preview.4" -Headers $AuthHeader
        }

        # Every context below builds its own full property set from this baseline (plus whatever
        # that context needs to add on top) instead of mutating one shared hashtable across
        # contexts. Each Invoke-DscResource call constructs a fresh class instance and validates
        # every [DscProperty(Mandatory)] property against exactly what it is handed that call - a
        # property set missing ConnectionType (or any other mandatory property) fails immediately
        # with "missing mandatory parameters: ConnectionType", so every context must supply the
        # full mandatory set on its own rather than relying on what an earlier context left behind.
        function New-SCProperty
        {
            param([HashTable]$Extra = @{})
            $base = @{
                ProjectName    = $PROJECTNAME
                ConnectionName = $SCNAME
                ConnectionType = 'Generic'
                Description    = 'Shared service connection test'
                Authorization  = @{
                    scheme   = 'UsernamePassword'
                    username = 'testuser'
                    password = 'testpassword'
                }
                Data           = @{
                    url = 'https://test.example.com'
                }
            }
            foreach ($key in $Extra.Keys) { $base[$key] = $Extra[$key] }
            return $base
        }

        New-TestProject -ProjectName $PROJECTNAME
        New-TestProject -ProjectName $PROJECTNAME2
        New-TestGroup   -ProjectName $PROJECTNAME -GroupName $GROUPNAME
    }

    Context "Creating the service connection unshared" {

        BeforeAll {
            $parameters = @{
                Name       = 'AzDoServiceConnection'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Set'
                property   = New-SCProperty
            }
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
            $connections = Get-TestServiceConnectionsForProject -ProjectName $PROJECTNAME2
            ($connections.value | Where-Object { $_.name -eq $SCNAME -or $_.name -eq $SHAREDNAME }) | Should -BeNullOrEmpty
        }
    }

    Context "Sharing the service connection with the second project" {

        BeforeAll {
            $parameters = @{
                Name       = 'AzDoServiceConnection'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Set'
                property   = New-SCProperty -Extra @{
                    SharedWithProjects  = @($PROJECTNAME2)
                    SharedNameOverrides = @{ $PROJECTNAME2 = $SHAREDNAME }
                }
            }
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
            $connections = Get-TestServiceConnectionsForProject -ProjectName $PROJECTNAME2
            $shared = $connections.value | Where-Object { $_.name -eq $SHAREDNAME }
            $shared | Should -Not -BeNullOrEmpty
        }
    }

    Context "Setting permissions on the shared service connection from the owning project" {

        BeforeAll {
            $permParameters = @{
                Name       = 'AzDoServiceConnectionPermission'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Set'
                property   = @{
                    ProjectName    = $PROJECTNAME
                    ConnectionName = $SCNAME
                    GroupName      = "[$PROJECTNAME]\$GROUPNAME"
                    isInherited    = $false
                    Permissions    = @(
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

        It "Should still resolve the ACL token against the owning project while the connection is shared" {
            $permParameters.Method = 'Test'
            $result = Invoke-DscResource @permParameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Unsharing the service connection from the second project" {

        BeforeAll {
            $parameters = @{
                Name       = 'AzDoServiceConnection'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Set'
                property   = New-SCProperty -Extra @{
                    SharedWithProjects = @()
                }
            }
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
            $connections = Get-TestServiceConnectionsForProject -ProjectName $PROJECTNAME2
            ($connections.value | Where-Object { $_.name -eq $SHAREDNAME -or $_.name -eq $SCNAME }) | Should -BeNullOrEmpty
        }
    }

    Context "Removing the service connection" {

        BeforeAll {
            $parameters = @{
                Name       = 'AzDoServiceConnection'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Set'
                property   = @{
                    ProjectName    = $PROJECTNAME
                    ConnectionName = $SCNAME
                    ConnectionType = 'Generic'
                    Ensure         = 'Absent'
                }
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
