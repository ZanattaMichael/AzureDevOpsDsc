Describe "AzDoProcessPermission Integration Tests" -Tag "Integration", "ProcessPermission" {

    BeforeAll {

        $GROUPNAME = 'ProcessPermGroup'

        # Process permissions apply at the organisation level ($PROCESS root). Create an org-level group
        # to grant the 'Create' permission to (i.e. the ability to create inherited/child processes).
        $body = @{ displayName = $GROUPNAME; description = 'Group for process permission testing' } | ConvertTo-Json
        try
        {
            $null = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$(Resolve-TestOrg)/_apis/graph/groups?api-version=7.1-preview.1" `
                -Method Post -Headers (Resolve-TestAuthHeader) -Body $body -ContentType 'application/json'
        }
        catch { if ("$_" -notmatch '409|already exist') { throw } }

        # 'AllProcesses' targets the org-wide root token ($PROCESS). The GroupName/Identity references an
        # organisation-level group descriptor ("[]\GroupName").
        $parameters = @{
            Name       = 'AzDoProcessPermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProcessName = 'AllProcesses'
                isInherited = $false
                Permissions = @(
                    @{
                        Identity   = "[]\$GROUPNAME"
                        Permission = @{
                            Create = 'Allow'
                            Edit   = 'Allow'
                        }
                    }
                )
            }
        }
    }

    Context "Testing if process permissions exist" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (permissions not yet set)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Setting process permissions" {

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
    }

    Context "Changing process permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity   = "[]\$GROUPNAME"
                    Permission = @{
                        Create = 'Allow'
                        Edit   = 'Deny'
                    }
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

    Context "Reverting to inherited permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @()
            $parameters.property.isInherited  = $true
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after reverting to inherited" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
