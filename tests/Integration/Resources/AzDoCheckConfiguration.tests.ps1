Describe "AzDoCheckConfiguration Integration Tests (Approval check on an environment)" {

    BeforeAll {

        $PROJECTNAME = 'TEST_CHECK_CONFIG'
        $ENVNAME     = 'TEST_CHECK_ENV'
        $ORG         = $GLOBAL:DSCAZDO_OrganizationName

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        function New-Environment { param([string]$ProjectName, [string]$EnvironmentName)
            $null = Invoke-DscResource -Name 'AzDoPipelineEnvironment' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName     = $ProjectName
                EnvironmentName = $EnvironmentName
            }
        }

        # Resolve a real identity id to use as the approver. We use the project's built-in
        # 'Project Administrators' group, scoped via the project's graph descriptor so the lookup
        # returns a small, single-page result.
        function Get-ApproverId { param([string]$Organization, [string]$ProjectName, [string]$GroupDisplayName)
            $proj   = Invoke-APIRestMethod -Uri ("https://dev.azure.com/{0}/_apis/projects/{1}?api-version=7.1-preview.4" -f $Organization, $ProjectName) -Method Get
            $desc   = Invoke-APIRestMethod -Uri ("https://vssps.dev.azure.com/{0}/_apis/graph/descriptors/{1}?api-version=7.1-preview.1" -f $Organization, $proj.id) -Method Get
            $groups = Invoke-APIRestMethod -Uri ("https://vssps.dev.azure.com/{0}/_apis/graph/groups?scopeDescriptor={1}&api-version=7.1-preview.1" -f $Organization, $desc.value) -Method Get
            $group  = $groups.value | Where-Object { $_.displayName -eq $GroupDisplayName } | Select-Object -First 1
            if (-not $group) { throw "[AzDoCheckConfiguration.tests] Could not resolve approver group '$GroupDisplayName' in '$ProjectName'." }
            return $group.originId
        }

        New-Project $PROJECTNAME
        New-Environment -ProjectName $PROJECTNAME -EnvironmentName $ENVNAME
        $APPROVERID = Get-ApproverId -Organization $ORG -ProjectName $PROJECTNAME -GroupDisplayName 'Project Administrators'

        # Approval check — the only check type verified against the Azure DevOps API.
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
