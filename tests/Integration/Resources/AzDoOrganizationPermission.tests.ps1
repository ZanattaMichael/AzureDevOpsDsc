Describe "AzDoOrganizationPermission Integration Tests" -Tag "Integration", "OrganizationPermission" {

    BeforeAll {

        $GROUPNAME = 'OrgPermGroup'

        # Organization permissions apply to the whole organization, so grant them to a group made for
        # this test and nothing else. Teardown removes non-system groups.
        $body = @{ displayName = $GROUPNAME; description = 'Group for organization permission testing' } | ConvertTo-Json
        try
        {
            $null = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$(Resolve-TestOrg)/_apis/graph/groups?api-version=7.1-preview.1" `
                -Method Post -Headers (Resolve-TestAuthHeader) -Body $body -ContentType 'application/json'
        }
        catch { if ("$_" -notmatch '409|already exist') { throw } }

        # Reads the organization root ACL straight from the API, to check that writing one group's
        # permissions leaves every other identity's entry in place.
        function Get-RootAceCount
        {
            $org        = Resolve-TestOrg
            $headers    = Resolve-TestAuthHeader
            $namespaces = Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/securitynamespaces?api-version=7.1-preview.1" -Headers $headers
            $collection = $namespaces.value | Where-Object { $_.name -eq 'Collection' } | Select-Object -First 1
            $acls       = Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/accesscontrollists/$($collection.namespaceId)?api-version=7.1" -Headers $headers
            $root       = $acls.value | Where-Object { $_.token -match '^NAMESPACE:?$' } | Select-Object -First 1
            return @($root.acesDictionary.PSObject.Properties).Count
        }

        $aceCountBefore = Get-RootAceCount

        $parameters = @{
            Name       = 'AzDoOrganizationPermission'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                GroupName   = "[]\$GROUPNAME"
                Permissions = @(
                    @{
                        Identity   = "[]\$GROUPNAME"
                        Permission = @{ CREATE_PROJECTS = 'Allow' }
                    }
                )
            }
        }
    }

    Context "Testing if organization permissions exist" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (permissions not yet set)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Setting organization permissions" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after setting permissions" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should keep every other identity's entry on the organization root" {
            # At least as many as before: an ACE left by an earlier, interrupted run is already
            # counted in the baseline. A write that dropped the other identities would leave one.
            (Get-RootAceCount) | Should -BeGreaterOrEqual $aceCountBefore
        }
    }

    Context "Changing organization permissions (drift and fix)" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity   = "[]\$GROUPNAME"
                    Permission = @{ CREATE_PROJECTS = 'Deny' }
                }
            )
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after changing permissions" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing organization permissions (Ensure = Absent)" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Ensure = 'Absent'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should clear only this group's entry" {
            Start-Sleep -Seconds 5
            # This group's entry may have been in the baseline (see above), so allow for one fewer.
            (Get-RootAceCount) | Should -BeGreaterOrEqual ($aceCountBefore - 1)
        }

        It "Should report the permissions as absent" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }
}
