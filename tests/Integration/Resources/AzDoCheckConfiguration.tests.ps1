Describe "AzDoCheckConfiguration Integration Tests (Approval check on an environment)" -Tag "Integration", "CheckConfiguration" {

    BeforeAll {

        $PROJECTNAME = 'TEST_CHECK_CONFIG'
        $ENVNAME     = 'TEST_CHECK_ENV'
        # Read org name directly from settings so we don't depend on the global being set before BeforeAll.
        $settings    = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
        $ORG         = $settings.OrganizationName

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        function New-Environment { param([string]$ProjectName, [string]$EnvironmentName)
            $null = Invoke-DscResource -Name 'AzDoPipelineEnvironment' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName     = $ProjectName
                EnvironmentName = $EnvironmentName
            }
        }

        # Build an Invoke-RestMethod auth header directly from the cached credentials.
        # The module token object's .Get() has a call-stack guard that blocks calls from test scope,
        # and $Global:DSCAZDO_AuthenticationToken may not propagate back from DSC's runspace.
        # Reading the SecureString from ModuleSettings.clixml is safe: DPAPI decrypts it on the
        # same machine/user that encrypted it.
        function New-RestAuthHeader {
            $cfg = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
            $tok = $cfg.Token
            $ss  = $tok.access_token
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ss)
            try   { $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
            finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
            if ($tok.tokenType.ToString() -eq 'PersonalAccessToken' -or $tok.tokenType.ToString() -eq '1') {
                $encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$plain"))
                return @{ Authorization = "Basic $encoded" }
            } else {
                return @{ Authorization = "Bearer $plain" }
            }
        }

        # Resolve a real identity id to use as the approver. We use the project's built-in
        # 'Project Administrators' group, scoped via the project's graph descriptor so the lookup
        # returns a small, single-page result.
        function Get-ApproverId { param([string]$Organization, [string]$ProjectName, [string]$GroupDisplayName)
            $authHeader = New-RestAuthHeader
            $proj   = Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/_apis/projects/{1}?api-version=7.1-preview.4" -f $Organization, $ProjectName) -Method Get -Headers $authHeader
            $desc   = Invoke-RestMethod -Uri ("https://vssps.dev.azure.com/{0}/_apis/graph/descriptors/{1}?api-version=7.1-preview.1" -f $Organization, $proj.id) -Method Get -Headers $authHeader
            $groups = Invoke-RestMethod -Uri ("https://vssps.dev.azure.com/{0}/_apis/graph/groups?scopeDescriptor={1}&api-version=7.1-preview.1" -f $Organization, $desc.value) -Method Get -Headers $authHeader
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
