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

        # The dev.azure.com policy route has no GET (_apis/OrganizationPolicy/Policies/{name}
        # answers 405), so read the policies the way the resource does: through the policy page's
        # data provider, then the page's own data route, then per policy from the SPS host.
        # Independent of the module's private functions, which are not loaded in this scope.
        # Each route that comes back empty says why, so a failure names the cause.
        function Get-LivePolicies {
            param([string[]]$PolicyName = $script:ManagedPolicyNames)

            $providerId = 'ms.vss-org-web.collection-admin-policy-data-provider'
            $groups     = $null
            $failures   = @()
            $body = @{
                contributionIds     = @($providerId)
                dataProviderContext = @{
                    properties = @{
                        sourcePage = @{
                            url         = "https://dev.azure.com/$ORGNAME/_settings/organizationPolicy"
                            routeId     = 'ms.vss-admin-web.collection-admin-hub-route'
                            routeValues = @{ adminPivot = 'organizationPolicy'; controller = 'ContributedPage'; action = 'Execute' }
                        }
                    }
                }
            } | ConvertTo-Json -Depth 10

            try
            {
                $response = Invoke-RestMethod -Uri "https://dev.azure.com/$ORGNAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1" `
                    -Method Post -Headers (New-RestAuthHeader) -ContentType 'application/json' -Body $body
                $groups = $response.dataProviders.$providerId.policies
                if ($null -eq $groups)
                {
                    $exception = $response.dataProviderExceptions.$providerId
                    $failures += if ($null -ne $exception) { "HierarchyQuery: the data provider failed: $($exception.message)" }
                                 else { "HierarchyQuery: no policy data (data providers returned: $(@($response.dataProviders.PSObject.Properties.Name) -join ', '))" }
                }
            }
            catch
            {
                $failures += "HierarchyQuery: $_"
            }

            if ($null -eq $groups)
            {
                try
                {
                    $response = Invoke-RestMethod -Uri "https://dev.azure.com/$ORGNAME/_settings/organizationPolicy?__rt=fps&__ver=2" `
                        -Method Get -Headers (New-RestAuthHeader)
                    $groups = $response.fps.dataProviders.data.$providerId.policies
                    if ($null -eq $groups)
                    {
                        $failures += if ($response -is [string]) { 'settings page data: a non-JSON response' }
                                     else { "settings page data: no policy data (response carried: $(@($response.PSObject.Properties.Name) -join ', '))" }
                    }
                }
                catch
                {
                    $failures += "settings page data: $_"
                }
            }

            if ($null -ne $groups)
            {
                foreach ($group in $groups.PSObject.Properties)
                {
                    foreach ($entry in @($group.Value)) { if ($null -ne $entry.policy) { $entry.policy } }
                }
                return
            }

            Write-Warning "[AzDoOrganizationSettings.Policies] Page routes returned no policy data, reading per policy from the SPS host: $($failures -join '; ')"
            foreach ($name in $PolicyName)
            {
                try
                {
                    $policy = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$ORGNAME/_apis/OrganizationPolicy/Policies/$($name)?api-version=5.0-preview.1" `
                        -Method Get -Headers (New-RestAuthHeader)
                }
                catch
                {
                    throw "No organization policy data from any route: $($failures -join '; '); SPS policy read ($name): $_"
                }
                if ($null -eq $policy.PSObject.Properties['name']) { $policy | Add-Member -NotePropertyName name -NotePropertyValue $name }
                $policy
            }
        }

        function Get-LivePolicyValue {
            param([Parameter(Mandatory)][string]$PolicyName)
            $policy = Get-LivePolicies -PolicyName $PolicyName | Where-Object { $_.name -eq $PolicyName } | Select-Object -First 1
            if ($null -eq $policy) { throw "Policy '$PolicyName' was not returned." }
            $raw = if ($null -ne $policy.PSObject.Properties['effectiveValue'] -and $null -ne $policy.effectiveValue) { $policy.effectiveValue } else { $policy.value }
            if ("$raw" -eq 'true') { 'true' } else { 'false' }
        }

        # The resource base class passes every DSC property to Get and Set, so the five host
        # settings ([bool], not tri-state) are always compared and always written. Pass them at
        # their current live values in every call, so toggling a policy here never rewrites the
        # organization's host settings. Values are derived exactly as Get-AzDoOrganizationSettings
        # derives them.
        $hostEntries = (Invoke-RestMethod -Uri "https://dev.azure.com/$ORGNAME/_apis/settings/entries/host?api-version=7.1-preview.1" `
            -Method Get -Headers (New-RestAuthHeader)).value
        $script:HostSettings = @{
            AllowPublicProjects        = $hostEntries.'Microsoft.VisualStudio.Services.EnablePublicProjects' -eq 'true'
            AllowExternalGuestAccess   = $hostEntries.'Microsoft.VisualStudio.Services.Security.EnableAADGuestPolicy' -eq 'false'
            EnableOAuthAuthentication  = $hostEntries.'Microsoft.VisualStudio.Services.Security.EnableOAuthToken' -eq 'true'
            EnableSSHAuthentication    = $hostEntries.'Microsoft.VisualStudio.Services.Security.EnableSSHPolicy' -eq 'true'
            DisallowAadGuestUserPolicy = $hostEntries.'Microsoft.VisualStudio.Services.Security.DisallowAADGuestUserPolicy' -eq 'true'
        }

        function New-PolicyProperty {
            param([hashtable]$Policy = @{})
            $property = @{ OrganizationName = $ORGNAME }
            foreach ($key in $script:HostSettings.Keys) { $property[$key] = $script:HostSettings[$key] }
            foreach ($key in $Policy.Keys) { $property[$key] = $Policy[$key] }
            return $property
        }

        function Get-Opposite {
            param([Parameter(Mandatory)][string]$Value)
            if ($Value -eq 'true') { 'false' } else { 'true' }
        }

        $parameters = @{
            Name       = 'AzDoOrganizationSettings'
            ModuleName = 'AzureDevOpsDscNative'
        }

        # Snapshot the two policies this suite is allowed to toggle live, so AfterAll can restore
        # them even if a test fails. Every other managed policy is read-only in this suite.
        $script:OriginalAllowTeamAdminsToInviteUsers = Get-LivePolicyValue -PolicyName 'Policy.AllowTeamAdminsInvitationsAccessToken'
        $script:OriginalLogAuditEvents               = Get-LivePolicyValue -PolicyName 'Policy.LogAuditEvents'
    }

    AfterAll {
        # Restore the two toggled policies regardless of test outcome.
        try
        {
            $parameters.Method   = 'Set'
            $parameters.property = New-PolicyProperty -Policy @{
                AllowTeamAdminsToInviteUsers = $script:OriginalAllowTeamAdminsToInviteUsers
                LogAuditEvents               = $script:OriginalLogAuditEvents
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
            $parameters.property = New-PolicyProperty
        }

        It "Should not throw retrieving the resource" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should find every managed policy name in the live policy data, so a wrong name fails loudly" {
            $liveNames = @(Get-LivePolicies | ForEach-Object { [string]$_.name })
            foreach ($policyName in $script:ManagedPolicyNames)
            {
                $liveNames | Should -Contain $policyName -Because "policy '$policyName' must exist for the resource to manage it"
            }
        }

        It "Should report every managed policy as 'true' or 'false' on the Get result" {
            $result = Invoke-DscResource @parameters
            $result.EnableIPConditionalAccessPolicyValidation | Should -BeIn @('true', 'false')
            $result.LogAuditEvents                            | Should -BeIn @('true', 'false')
            $result.AllowTeamAdminsToInviteUsers              | Should -BeIn @('true', 'false')
            $result.EnableRequestAccess                       | Should -BeIn @('true', 'false')
            $result.EnableArtifactsFeedUpstreamProtection     | Should -BeIn @('true', 'false')
        }

        It "Should report the same policy values the live data shows" {
            $result = Invoke-DscResource @parameters
            $result.LogAuditEvents               | Should -Be $script:OriginalLogAuditEvents
            $result.AllowTeamAdminsToInviteUsers | Should -Be $script:OriginalAllowTeamAdminsToInviteUsers
        }
    }

    Context "Setting AllowTeamAdminsToInviteUsers (user policy) and asserting no drift" {

        It "Should apply the desired value without throwing" {
            $desired = Get-Opposite $script:OriginalAllowTeamAdminsToInviteUsers

            $parameters.Method   = 'Set'
            $parameters.property = New-PolicyProperty -Policy @{ AllowTeamAdminsToInviteUsers = $desired }
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $script:ToggledAllowTeamAdminsToInviteUsers = $desired
        }

        It "Should have written the value to the live policy" {
            Get-LivePolicyValue -PolicyName 'Policy.AllowTeamAdminsInvitationsAccessToken' | Should -Be $script:ToggledAllowTeamAdminsToInviteUsers
        }

        It "Should report no drift (Test) once applied" {
            $parameters.Method   = 'Test'
            $parameters.property = New-PolicyProperty -Policy @{ AllowTeamAdminsToInviteUsers = $script:ToggledAllowTeamAdminsToInviteUsers }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should report drift when the opposite value is requested, and Set fixes it" {
            $driftValue = Get-Opposite $script:ToggledAllowTeamAdminsToInviteUsers

            $parameters.Method   = 'Test'
            $parameters.property = New-PolicyProperty -Policy @{ AllowTeamAdminsToInviteUsers = $driftValue }
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse

            $parameters.Method   = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $parameters.Method   = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue

            $script:ToggledAllowTeamAdminsToInviteUsers = $driftValue
        }
    }

    Context "Setting LogAuditEvents (security policy) and asserting no drift" {

        It "Should apply the desired value without throwing" {
            $desired = Get-Opposite $script:OriginalLogAuditEvents

            $parameters.Method   = 'Set'
            $parameters.property = New-PolicyProperty -Policy @{ LogAuditEvents = $desired }
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $script:ToggledLogAuditEvents = $desired
        }

        It "Should report no drift (Test) once applied" {
            $parameters.Method   = 'Test'
            $parameters.property = New-PolicyProperty -Policy @{ LogAuditEvents = $script:ToggledLogAuditEvents }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "An unmanaged policy property is never compared or written" {

        It "Should not report drift for policies the configuration does not mention" {
            # Only LogAuditEvents is managed here. AllowTeamAdminsToInviteUsers,
            # EnableIPConditionalAccessPolicyValidation, EnableRequestAccess and
            # EnableArtifactsFeedUpstreamProtection are left at '' (unmanaged) - none of them may
            # cause drift whatever their live value.
            $parameters.Method   = 'Test'
            $parameters.property = New-PolicyProperty -Policy @{ LogAuditEvents = $script:ToggledLogAuditEvents }
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should leave an unmanaged policy unchanged when Set runs" {
            $before = Get-LivePolicyValue -PolicyName 'Policy.AllowTeamAdminsInvitationsAccessToken'

            $parameters.Method   = 'Set'
            $parameters.property = New-PolicyProperty -Policy @{ LogAuditEvents = $script:ToggledLogAuditEvents }
            { Invoke-DscResource @parameters } | Should -Not -Throw

            Get-LivePolicyValue -PolicyName 'Policy.AllowTeamAdminsInvitationsAccessToken' | Should -Be $before
        }
    }
}
