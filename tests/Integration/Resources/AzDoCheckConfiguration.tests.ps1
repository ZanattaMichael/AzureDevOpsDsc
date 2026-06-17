Describe "AzDoCheckConfiguration Integration Tests (Approval check on an environment)" -Tag "Integration", "CheckConfiguration" {

    BeforeAll {

        $PROJECTNAME = 'TEST_CHECK_CONFIG'
        $ENVNAME     = 'TEST_CHECK_ENV'

        New-TestProject             -ProjectName $PROJECTNAME
        New-TestPipelineEnvironment -ProjectName $PROJECTNAME -EnvironmentName $ENVNAME

        # Resolve a real identity id to use as the approver using the project's built-in
        # 'Project Administrators' group, scoped via the project's graph descriptor.
        $org_    = Resolve-TestOrg
        $hdr_    = Resolve-TestAuthHeader
        $proj    = Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/_apis/projects/{1}?api-version=7.1-preview.4" -f $org_, $PROJECTNAME) -Headers $hdr_
        $desc    = Invoke-RestMethod -Uri ("https://vssps.dev.azure.com/{0}/_apis/graph/descriptors/{1}?api-version=7.1-preview.1" -f $org_, $proj.id) -Headers $hdr_
        $groups  = Invoke-RestMethod -Uri ("https://vssps.dev.azure.com/{0}/_apis/graph/groups?scopeDescriptor={1}&api-version=7.1-preview.1" -f $org_, $desc.value) -Headers $hdr_
        $group   = $groups.value | Where-Object { $_.displayName -eq 'Project Administrators' } | Select-Object -First 1
        if (-not $group) { throw "[AzDoCheckConfiguration.tests] Could not resolve 'Project Administrators' in '$PROJECTNAME'." }
        $APPROVERID = $group.originId

        $parameters = @{
            Name       = 'AzDoCheckConfiguration'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName        = $PROJECTNAME
                TargetResourceName = $ENVNAME
                ResourceType       = 'environment'
                CheckType          = 'Approval'
                Settings           = @{
                    approvers            = @( @{ id = $APPROVERID } )
                    executionOrder       = 'anyOrder'
                    minRequiredApprovers = 1
                    instructions         = 'Please review before deploying.'
                    blockedApprovers     = @()
                }
                TimeoutInMinutes   = 43200
                Enabled            = $true
            }
        }
    }

    Context "Testing if the Approval check configuration exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions when testing the Approval check" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (Approval check not yet created)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the Approval check configuration" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions when creating the Approval check" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the Approval check" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the Approval check configuration" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Settings.instructions = 'Updated review instructions.'
        }

        It "Should not throw any exceptions when updating the Approval check" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after updating the Approval check" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the Approval check configuration" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName        = $PROJECTNAME
                TargetResourceName = $ENVNAME
                ResourceType       = 'environment'
                CheckType          = 'Approval'
                Settings           = @{}
                Ensure             = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the Approval check" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Approval check absent is the desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
