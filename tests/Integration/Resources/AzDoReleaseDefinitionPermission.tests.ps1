Describe "AzDoReleaseDefinitionPermission Integration Tests" -Tag "Integration", "ReleaseDefinition", "Permission" {

    BeforeAll {

        $PROJECTNAME    = 'TEST_RELEASEDEFPERM'
        $DEFINITIONNAME = 'DSC_TEST_RELEASE_DEFINITION'

        $org = Resolve-TestOrg
        $hdr = Resolve-TestAuthHeader

        # AzDoReleaseDefinition (the resource that will manage definitions themselves) has not
        # landed yet - this creates a minimal definition directly, the same way New-RestAuthHeader
        # is used elsewhere to reach the API without Invoke-AzDevOpsApiRestMethod.
        function New-TestReleaseDefinition
        {
            param([string]$ProjectName, [string]$DefinitionName)

            $body = @{
                name              = $DefinitionName
                releaseNameFormat = 'Release-$(rev:r)'
                artifacts         = @()
                triggers          = @()
                environments      = @(
                    @{
                        name                = 'Environment 1'
                        rank                = 1
                        retentionPolicy     = @{ daysToKeep = 30; releasesToKeep = 3; retainBuild = $true }
                        preDeployApprovals  = @{ approvals = @(@{ rank = 1; isAutomated = $true; isNotificationOn = $false }) }
                        postDeployApprovals = @{ approvals = @(@{ rank = 1; isAutomated = $true; isNotificationOn = $false }) }
                        deployStep          = @{ id = 1 }
                        deployPhases        = @()
                    }
                )
            } | ConvertTo-Json -Depth 10

            return Invoke-RestMethod -Headers $hdr -Method Post -ContentType 'application/json' -Body $body -Uri (
                'https://vsrm.dev.azure.com/{0}/{1}/_apis/release/definitions?api-version=7.1' -f $org, $ProjectName)
        }

        function Remove-TestReleaseDefinition
        {
            param([string]$ProjectName, [int]$DefinitionId)

            try {
                Invoke-RestMethod -Headers $hdr -Method Delete -Uri (
                    'https://vsrm.dev.azure.com/{0}/{1}/_apis/release/definitions/{2}?api-version=7.1' -f $org, $ProjectName, $DefinitionId) | Out-Null
            } catch {
                Write-Warning "[Remove-TestReleaseDefinition] Failed to delete definition '$DefinitionId'. Error: $_"
            }
        }

        New-TestProject -ProjectName $PROJECTNAME

        $script:definition = New-TestReleaseDefinition -ProjectName $PROJECTNAME -DefinitionName $DEFINITIONNAME

        $parameters = @{
            Name       = 'AzDoReleaseDefinitionPermission'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName    = $PROJECTNAME
                DefinitionName = $DEFINITIONNAME
                isInherited    = $false
                Permissions    = @(
                    @{
                        Identity   = "[$PROJECTNAME]\$PROJECTNAME Team"
                        Permission = @{
                            ViewReleaseDefinition  = 'Allow'
                            ManageReleaseApprovers = 'Allow'
                        }
                    }
                )
            }
        }
    }

    AfterAll {
        if ($script:definition) {
            Remove-TestReleaseDefinition -ProjectName $PROJECTNAME -DefinitionId $script:definition.id
        }
    }

    Context "Testing permissions on the release definition" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the release definition permissions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }

    Context "Setting permissions on the release definition" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when setting the release definition permissions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after setting the permissions" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should remain in the desired state when tested repeatedly" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the release definition permissions" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName    = $PROJECTNAME
                DefinitionName = $DEFINITIONNAME
                isInherited    = $false
                Permissions    = @(
                    @{
                        Identity   = "[$PROJECTNAME]\$PROJECTNAME Team"
                        Permission = @{ ViewReleaseDefinition = 'Allow' }
                    }
                )
                Ensure         = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the release definition permissions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }
}
