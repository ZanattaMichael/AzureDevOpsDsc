Describe "AzDoOrgPipelineSettings Integration Tests" -Tag "Integration", "PipelineSettings" {

    # This resource is a singleton at organization scope, shared by every other test running against
    # this live organization. Only the two switches the resource brief calls harmless
    # (StatusBadgesArePrivate, PublishPipelineMetadata) are ever set here. EnforceJobAuthScope*,
    # the classic-pipeline-creation switches and the task switches are read-only in this file.
    #
    # The original org values are snapshotted in BeforeAll and restored in AfterAll (even on
    # failure), so a failed assertion never leaves the shared organization changed.

    function New-RestAuthHeader
    {
        $cfg  = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
        $tok  = $cfg.Token
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($tok.access_token)
        try   { $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
        finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
        if ($tok.tokenType.ToString() -eq 'PersonalAccessToken' -or $tok.tokenType.ToString() -eq '1')
        {
            $encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$plain"))
            return @{ Authorization = "Basic $encoded" }
        }
        else
        {
            return @{ Authorization = "Bearer $plain" }
        }
    }

    BeforeAll {

        $settings   = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
        $ORGNAME    = $settings.OrganizationName
        $authHeader = New-RestAuthHeader
        $orgUri     = "https://dev.azure.com/$ORGNAME/_apis/build/generalsettings?api-version=7.1"

        $liveBefore = Invoke-RestMethod -Uri $orgUri -Method Get -Headers $authHeader
        $script:originalOrgSettings = @{
            statusBadgesArePrivate  = [bool]$liveBefore.statusBadgesArePrivate
            publishPipelineMetadata = [bool]$liveBefore.publishPipelineMetadata
        }

        $PROJECTNAME = 'TEST_ORG_PIPELINE_SETTINGS'
        New-TestProject -ProjectName $PROJECTNAME -Organization $ORGNAME -AuthHeader $authHeader

        $parameters = @{
            Name       = 'AzDoOrgPipelineSettings'
            ModuleName = 'AzureDevOpsDscNative'
        }
        $projectParameters = @{
            Name       = 'AzDoPipelineSettings'
            ModuleName = 'AzureDevOpsDscNative'
        }
    }

    AfterAll {

        # Restore the org's original values, whatever happened above.
        try
        {
            $ORGNAME    = $settings.OrganizationName
            $authHeader = New-RestAuthHeader
            $orgUri     = "https://dev.azure.com/$ORGNAME/_apis/build/generalsettings?api-version=7.1"
            $body = @{
                statusBadgesArePrivate  = $script:originalOrgSettings.statusBadgesArePrivate
                publishPipelineMetadata = $script:originalOrgSettings.publishPipelineMetadata
            } | ConvertTo-Json
            $null = Invoke-RestMethod -Uri $orgUri -Method Patch -Headers $authHeader -Body $body -ContentType 'application/json'
        }
        catch
        {
            Write-Warning "[AzDoOrgPipelineSettings.tests] Failed to restore original organization pipeline settings: $_"
        }
    }

    Context "Reading organization pipeline settings (Get)" {

        BeforeAll {
            $parameters.Method   = 'Get'
            $parameters.property = @{ OrganizationName = $ORGNAME }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return every key this resource manages" {
            $result = Invoke-DscResource @parameters
            @(
                'EnforceJobAuthScope', 'EnforceJobAuthScopeForReleases', 'EnforceReferencedRepoScopedToken',
                'EnforceSettableVar', 'PublishPipelineMetadata', 'StatusBadgesArePrivate',
                'DisableClassicPipelineCreation', 'DisableImpliedYAMLCiTrigger'
            ) | ForEach-Object {
                $result.PSObject.Properties.Name | Should -Contain $_
            }
        }
    }

    Context "Applying an organization pipeline setting" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw when setting StatusBadgesArePrivate" {
            $parameters.property = @{
                OrganizationName       = $ORGNAME
                StatusBadgesArePrivate = 'true'
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in the desired state after applying (no drift)" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Changing an organization pipeline setting (drift and fix)" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                OrganizationName       = $ORGNAME
                StatusBadgesArePrivate = 'false'
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after the change" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Organization lock propagates to the project-scoped resource" {

        # Force StatusBadgesArePrivate ON at organization level, then confirm the project resource
        # (a) marks it Locked instead of drifted when the project desires it off, (b) reports
        # InDesiredState True for that reason, and (c) never PATCHes it (no error, no throw).

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                OrganizationName       = $ORGNAME
                StatusBadgesArePrivate = 'true'
            }
            $null = Invoke-DscResource @parameters
            Start-Sleep -Seconds 5

            $projectParameters.Method   = 'Get'
            $projectParameters.property = @{
                ProjectName            = $PROJECTNAME
                StatusBadgesArePrivate = 'false'
            }
        }

        It "Marks the property Locked at the project level and does not report it as drift" {
            $result = Invoke-DscResource @projectParameters
            @($result.LockedProperties) | Should -Contain 'StatusBadgesArePrivate'
            @($result.propertiesChanged) | Should -Not -Contain 'StatusBadgesArePrivate'
        }

        It "Reports InDesiredState True and never throws applying the locked desired state" {
            $projectParameters.Method = 'Test'
            $result = $null
            { $result = Invoke-DscResource @projectParameters } | Should -Not -Throw
            $result.InDesiredState | Should -BeTrue
        }
    }
}
