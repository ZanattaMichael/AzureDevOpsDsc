Describe "AzDoCheckConfiguration Integration Tests (Approval check on an environment)" -Tag "Integration", "CheckConfiguration" {

    BeforeAll {

        $PROJECTNAME = 'TEST_CHECK_CONFIG'
        $ENVNAME     = 'TEST_CHECK_ENV'

        $authHeader = New-TestAuthHeader
        $ORG        = Get-TestOrganizationName

        New-TestProject             -Organization $ORG -ProjectName $PROJECTNAME -AuthHeader $authHeader
        New-TestPipelineEnvironment -Organization $ORG -ProjectName $PROJECTNAME -EnvironmentName $ENVNAME -AuthHeader $authHeader

        # Resolve a real identity id to use as the approver using the project's built-in
        # 'Project Administrators' group, scoped via the project's graph descriptor.
        $proj   = Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/_apis/projects/{1}?api-version=7.1-preview.4" -f $ORG, $PROJECTNAME) -Headers $authHeader
        $desc   = Invoke-RestMethod -Uri ("https://vssps.dev.azure.com/{0}/_apis/graph/descriptors/{1}?api-version=7.1-preview.1" -f $ORG, $proj.id) -Headers $authHeader
        $groups = Invoke-RestMethod -Uri ("https://vssps.dev.azure.com/{0}/_apis/graph/groups?scopeDescriptor={1}&api-version=7.1-preview.1" -f $ORG, $desc.value) -Headers $authHeader
        $group  = $groups.value | Where-Object { $_.displayName -eq 'Project Administrators' } | Select-Object -First 1
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
