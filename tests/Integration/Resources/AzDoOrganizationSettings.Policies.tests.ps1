Describe "AzDoOrganizationSettings Policies Integration Tests" -Tag "Integration", "OrganizationSettings" {

    BeforeAll {

        # Read the org name from the module settings file so this test does not depend on
        # $Global:DSCAZDO_OrganizationName being pre-populated before BeforeAll runs.
        $settings = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
        $ORGNAME  = $settings.OrganizationName

        function New-RestAuthHeader {
            $cfg  = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
            $tok  = $cfg.Token
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($tok.access_token)
            try   { $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
            finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
            if ($tok.tokenType.ToString() -eq 'PersonalAccessToken' -or $tok.tokenType.ToString() -eq '1') {
                $encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$plain"))
                return @{ Authorization = "Basic $encoded" }
            } else {
                return @{ Authorization = "Bearer $plain" }
            }
        }

        # Every managed policy name, so a wrong name or a wrong route fails loudly rather than
        # silently reading nothing.
        $script:ManagedPolicyNames = @(
            'Policy.EnforceAADConditionalAccess',
            'Policy.LogAuditEvents',
            'Policy.AllowTeamAdminsInvitationsAccessToken',
            'Policy.AllowRequestAccessToken',
            'Policy.ArtifactsExternalPackageProtectionToken'
        )

        function Get-LivePolicy {
            param([Parameter(Mandatory)][string]$PolicyName)
            $uri = 'https://dev.azure.com/{0}/_apis/OrganizationPolicy/Policies/{1}?api-version=5.0-preview.1' -f $ORGNAME, $PolicyName
            return Invoke-RestMethod -Uri $uri -Method Get -Headers (New-RestAuthHeader)
        }

        $parameters = @{
            Name       = 'AzDoOrganizationSettings'
            ModuleName = 'AzureDevOpsDscNative'
        }

        # Snapshot the two policies this suite is allowed to toggle live, so AfterAll can restore
        # them even if a test fails. Every other managed policy is read-only in this suite.
        $script:OriginalAllowTeamAdminsToInviteUsers = [bool](Get-LivePolicy -PolicyName 'Policy.AllowTeamAdminsInvitationsAccessToken').value
        $script:OriginalLogAuditEvents               = [bool](Get-LivePolicy -PolicyName 'Policy.LogAuditEvents').value
    }

    AfterAll {
        # Restore the two toggled policies regardless of test outcome.
        try
        {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                OrganizationName              = $ORGNAME
                AllowTeamAdminsToInviteUsers  = $script:OriginalAllowTeamAdminsToInviteUsers
                LogAuditEvents                = $script:OriginalLogAuditEvents
            }
            Invoke-DscResource @parameters
        }
        catch
        {
            Write-Warning "[AzDoOrganizationSettings.Policies] Failed to restore original policy values: $_"
        }
    }

    Context "Every managed organization policy is reachable through the resource's Get" {

        BeforeAll {
            $parameters.Method   = 'Get'
            $parameters.property = @{ OrganizationName = $ORGNAME }
        }

        It "Should not throw retrieving the resource" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should read every managed policy name directly, so a wrong name or route fails loudly" {
            foreach ($policyName in $script:ManagedPolicyNames)
            {
                { Get-LivePolicy -PolicyName $policyName } | Should -Not -Throw -Because "policy '$policyName' must exist at the route the resource uses"
            }
        }

        It "Should surface the read-only-in-this-suite policies on the Get result" {
            $result = Invoke-DscResource @parameters
            $result.EnableIPConditionalAccessPolicyValidation | Should -BeOfType [bool]
            $result.EnableRequestAccess | Should -BeOfType [bool]
            $result.EnableArtifactsFeedUpstreamProtection | Should -BeOfType [bool]
        }
    }

    Context "Setting AllowTeamAdminsToInviteUsers (user policy) and asserting no drift" {

        It "Should apply the desired value without throwing" {
            $desired = -not $script:OriginalAllowTeamAdminsToInviteUsers

            $parameters.Method   = 'Set'
            $parameters.property = @{
                OrganizationName             = $ORGNAME
                AllowTeamAdminsToInviteUsers = $desired
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $script:ToggledAllowTeamAdminsToInviteUsers = $desired
        }

        It "Should report no drift (Test) once applied" {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                OrganizationName             = $ORGNAME
                AllowTeamAdminsToInviteUsers = $script:ToggledAllowTeamAdminsToInviteUsers
            }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should report drift when the opposite value is requested, and Set fixes it" {
            $driftValue = -not $script:ToggledAllowTeamAdminsToInviteUsers

            $parameters.Method   = 'Test'
            $parameters.property = @{
                OrganizationName             = $ORGNAME
                AllowTeamAdminsToInviteUsers = $driftValue
            }
            $testResult = Invoke-DscResource @parameters
            $testResult.InDesiredState | Should -BeFalse

            $parameters.Method   = 'Set'
            $parameters.property = @{
                OrganizationName             = $ORGNAME
                AllowTeamAdminsToInviteUsers = $driftValue
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $parameters.Method   = 'Test'
            $parameters.property = @{
                OrganizationName             = $ORGNAME
                AllowTeamAdminsToInviteUsers = $driftValue
            }
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue

            $script:ToggledAllowTeamAdminsToInviteUsers = $driftValue
        }
    }

    Context "Setting LogAuditEvents (security policy) and asserting no drift" {

        It "Should apply the desired value without throwing" {
            $desired = -not $script:OriginalLogAuditEvents

            $parameters.Method   = 'Set'
            $parameters.property = @{
                OrganizationName = $ORGNAME
                LogAuditEvents   = $desired
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $script:ToggledLogAuditEvents = $desired
        }

        It "Should report no drift (Test) once applied" {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                OrganizationName = $ORGNAME
                LogAuditEvents   = $script:ToggledLogAuditEvents
            }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "An unbound property is never compared" {

        It "Should not report drift for a property the configuration does not mention" {
            # Only OrganizationName and LogAuditEvents are bound. AllowTeamAdminsToInviteUsers,
            # EnableIPConditionalAccessPolicyValidation, EnableRequestAccess and
            # EnableArtifactsFeedUpstreamProtection are intentionally left unset here - none of
            # them may cause drift even if their live value differs from any prior test run.
            $parameters.Method   = 'Test'
            $parameters.property = @{
                OrganizationName = $ORGNAME
                LogAuditEvents   = $script:ToggledLogAuditEvents
            }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
