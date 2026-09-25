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
            ModuleName = 'AzureDevOpsDscNative'
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

Describe "AzDoCheckConfiguration Integration Tests (Branch control check on a variable group)" -Tag "Integration", "CheckConfiguration" {

    BeforeAll {

        $VG_PROJECTNAME = 'TEST_CHECK_CONFIG_VG'
        $VG_NAME        = 'TEST_CHECK_VG'

        New-TestProject -ProjectName $VG_PROJECTNAME

        # Create the variable group the Branch control check will attach to, using the existing
        # AzDoVariableGroup resource (see AzDoVariableGroup.tests.ps1 for the same pattern).
        $vgParameters = @{
            Name       = 'AzDoVariableGroup'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName       = $VG_PROJECTNAME
                VariableGroupName = $VG_NAME
                Description       = 'Variable group for Branch control check integration test'
                Variables         = @{
                    MyVar1 = @{ value = 'Value1'; isSecret = $false }
                }
            }
            Method     = 'Set'
        }
        Invoke-DscResource @vgParameters | Out-Null

        $org_ = Resolve-TestOrg
        $hdr_ = Resolve-TestAuthHeader

        # Resolve the variable group's id directly via the REST API so the check-existence
        # assertion below does not depend on the module's own cache/resolution helper.
        $vgList = Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/{1}/_apis/distributedtask/variablegroups?api-version=7.1-preview.2" -f $org_, $VG_PROJECTNAME) -Headers $hdr_
        $vg     = $vgList.value | Where-Object { $_.name -eq $VG_NAME } | Select-Object -First 1
        if (-not $vg) { throw "[AzDoCheckConfiguration.tests] Could not resolve variable group '$VG_NAME' in '$VG_PROJECTNAME'." }
        $VG_ID = $vg.id

        # Branch control is a generic "Task Check" (shared type.id fe1de3ee-a436-41b4-bb20-f6eb4cb879a7)
        # selected via Settings.definitionRef - see source/Examples/Resources/AzDoCheckConfiguration.md
        # Example 4 and New-AzDoCheckConfiguration.ps1's $checkTypeMap for the sourcing of these ids.
        $parameters = @{
            Name       = 'AzDoCheckConfiguration'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName        = $VG_PROJECTNAME
                TargetResourceName = $VG_NAME
                ResourceType       = 'variablegroup'
                CheckType          = 'BranchControl'
                Settings           = @{
                    definitionRef = @{
                        id      = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'
                        name    = 'evaluatebranchProtection'
                        version = '0.0.1'
                    }
                    displayName = 'Branch control'
                    inputs      = @{
                        allowedBranches          = 'refs/heads/main'
                        ensureProtectionOfBranch = 'true'
                        allowUnknownStatusBranch = 'false'
                    }
                }
                TimeoutInMinutes   = 43200
                Enabled            = $true
            }
        }
    }

    Context "Testing if the Branch control check configuration exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions when testing the Branch control check" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (Branch control check not yet created)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the Branch control check configuration" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions when creating the Branch control check" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the Branch control check" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should exist on the variable group when queried directly via the REST API" {
            $checks = Invoke-RestMethod -Uri ('https://dev.azure.com/{0}/{1}/_apis/pipelines/checks/configurations?resourceType=variablegroup&resourceId={2}&$expand=settings&api-version=7.1-preview.1' -f $org_, $VG_PROJECTNAME, $VG_ID) -Headers $hdr_
            $match  = $checks.value | Where-Object { $_.settings.definitionRef.id -eq '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b' }
            $match  | Should -Not -BeNullOrEmpty -Because ('the variable group returned these checks: {0}' -f ($checks.value | ConvertTo-Json -Depth 6 -Compress))
            $match.resource.id | Should -Be $VG_ID
        }
    }

    Context "Removing the Branch control check configuration" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName        = $VG_PROJECTNAME
                TargetResourceName = $VG_NAME
                ResourceType       = 'variablegroup'
                CheckType          = 'BranchControl'
                Settings           = @{}
                Ensure             = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the Branch control check" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Branch control check absent is the desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should no longer exist on the variable group when queried directly via the REST API" {
            $checks = Invoke-RestMethod -Uri ('https://dev.azure.com/{0}/{1}/_apis/pipelines/checks/configurations?resourceType=variablegroup&resourceId={2}&$expand=settings&api-version=7.1-preview.1' -f $org_, $VG_PROJECTNAME, $VG_ID) -Headers $hdr_
            $match  = $checks.value | Where-Object { $_.settings.definitionRef.id -eq '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b' }
            $match | Should -BeNullOrEmpty
        }
    }

    AfterAll {

        # Best-effort cleanup: remove the Branch control check (if the last Context failed before
        # doing so) and the variable group, so a failed run does not leave live resources behind.
        try {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName        = $VG_PROJECTNAME
                TargetResourceName = $VG_NAME
                ResourceType       = 'variablegroup'
                CheckType          = 'BranchControl'
                Settings           = @{}
                Ensure             = 'Absent'
            }
            Invoke-DscResource @parameters | Out-Null
        } catch {}

        try {
            $vgParameters.Method = 'Set'
            $vgParameters.property = @{
                ProjectName       = $VG_PROJECTNAME
                VariableGroupName = $VG_NAME
                Ensure            = 'Absent'
            }
            Invoke-DscResource @vgParameters | Out-Null
        } catch {}
    }
}
