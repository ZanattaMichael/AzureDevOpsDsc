Describe "AzDoProcessPermission Integration Tests" -Tag "Integration", "ProcessPermission" {

    BeforeAll {

        $GROUPNAME  = 'ProcessPermGroup'
        $GROUPNAME2 = 'ProcessPermGroup2'

        # Process permissions apply at the organisation level ($PROCESS root). Create an org-level group
        # to grant the 'Create' permission to (i.e. the ability to create inherited/child processes).
        $body = @{ displayName = $GROUPNAME; description = 'Group for process permission testing' } | ConvertTo-Json
        try
        {
            $null = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$(Resolve-TestOrg)/_apis/graph/groups?api-version=7.1-preview.1" `
                -Method Post -Headers (Resolve-TestAuthHeader) -Body $body -ContentType 'application/json'
        }
        catch { if ("$_" -notmatch '409|already exist') { throw } }

        # Second org-level group, used by the multi-identity Contexts below to mirror the production
        # shape: a resource granting TWO different identities permissions in the same ACL, one of them
        # with a mix of Allow and Deny actions (e.g. 'Process Administrators' + 'Security Auditors' in
        # the real config). Every other Context in this file only ever exercises a single identity.
        $body2 = @{ displayName = $GROUPNAME2; description = 'Second group for process permission testing' } | ConvertTo-Json
        try
        {
            $null = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$(Resolve-TestOrg)/_apis/graph/groups?api-version=7.1-preview.1" `
                -Method Post -Headers (Resolve-TestAuthHeader) -Body $body2 -ContentType 'application/json'
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

    Context "Setting process permissions for two identities (both Allow-only)" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity   = "[]\$GROUPNAME"
                    Permission = @{
                        Create = 'Allow'
                        Edit   = 'Allow'
                    }
                },
                @{
                    Identity   = "[]\$GROUPNAME2"
                    Permission = @{
                        Create = 'Allow'
                    }
                }
            )
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after setting permissions for both identities" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Setting process permissions for two identities (one mixed Allow/Deny)" {

        BeforeAll {
            $parameters.Method = 'Set'
            # Mirrors the production shape that surfaced this bug: one identity with a pure-Allow ACE
            # alongside a second identity whose ACE mixes Allow and Deny actions (e.g. a read-only
            # 'Security Auditors'-style role: ReadProcessPermissions Allow, Edit/Delete Deny).
            $parameters.property.Permissions = @(
                @{
                    Identity   = "[]\$GROUPNAME"
                    Permission = @{
                        Create = 'Allow'
                        Edit   = 'Allow'
                    }
                },
                @{
                    Identity   = "[]\$GROUPNAME2"
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

        It "Should return True after setting mixed Allow/Deny permissions for both identities" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should still report True on a second, independent Test (no flapping/false drift)" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Setting permissions on a specific inherited process (not the AllProcesses root)" {

        # Every Context above - and every pre-existing test in this file - targets ProcessName
        # 'AllProcesses', which resolves directly to the literal '$PROCESS' root token
        # (Get-DevOpsProcessAclToken's early-return). The production resource that surfaced this bug
        # ('Process Administrators Permissions') instead targets the PROJECT'S OWN inherited process
        # (ProcessName: $ProcessName), which resolves to a per-process token
        # '$PROCESS:{parentProcessTypeId}:{processTypeId}' via Resolve-DevOpsProcess + Get-DevOpsProcess -
        # a materially different code path. Reproduce that exact shape here.

        BeforeAll {
            $PROCESSNAME = "ITProcessPerm$(Get-Random -Maximum 99999)"

            $null = Invoke-DscResource -Name 'AzDoProcess' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProcessName       = $PROCESSNAME
                ParentProcessName = 'Agile'
                Description       = 'Inherited process for process-permission scope testing'
            }
            Start-Sleep -Seconds 5

            $processParameters = @{
                Name       = 'AzDoProcessPermission'
                ModuleName = 'AzureDevOpsDsc'
                property   = @{
                    ProcessName = $PROCESSNAME
                    isInherited = $false
                    Permissions = @(
                        @{
                            Identity   = "[]\$GROUPNAME"
                            Permission = @{
                                Create = 'Allow'
                                Edit   = 'Allow'
                            }
                        },
                        @{
                            Identity   = "[]\$GROUPNAME2"
                            Permission = @{
                                Create = 'Allow'
                                Edit   = 'Deny'
                            }
                        }
                    )
                }
            }
        }

        AfterAll {
            $null = Invoke-DscResource -Name 'AzDoProcess' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProcessName       = $PROCESSNAME
                ParentProcessName = 'Agile'
                Ensure            = 'Absent'
            }
        }

        It "Should not throw any exceptions on Set" {
            $processParameters.Method = 'Set'
            { Invoke-DscResource @processParameters } | Should -Not -Throw
        }

        It "Should return True after setting mixed Allow/Deny permissions on the specific process" {
            Start-Sleep -Seconds 5
            $processParameters.Method = 'Test'
            $result = Invoke-DscResource @processParameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should still report True on a second, independent Test (no flapping/false drift)" {
            Start-Sleep -Seconds 5
            $processParameters.Method = 'Test'
            $result = Invoke-DscResource @processParameters
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
