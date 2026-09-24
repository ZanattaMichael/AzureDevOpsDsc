$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoOrganizationSettings" -Tag "Unit", "OrganizationSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoOrganizationSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Write-Warning
        # Get-DevOpsOrganizationPolicy returns every policy at once, as objects shaped like the
        # data provider's policy entries.
        function New-LivePolicyList {
            param([hashtable]$Values = @{}, [string]$RequestAccessUrl = '')
            $names = 'Policy.EnforceAADConditionalAccess', 'Policy.LogAuditEvents', 'Policy.AllowTeamAdminsInvitationsAccessToken',
                     'Policy.AllowRequestAccessToken', 'Policy.ArtifactsExternalPackageProtectionToken'
            foreach ($name in $names)
            {
                $value = if ($Values.ContainsKey($name)) { $Values[$name] } else { $false }
                $policy = [PSCustomObject]@{ name = $name; value = $value; effectiveValue = $value }
                if ($name -eq 'Policy.AllowRequestAccessToken') { $policy | Add-Member -NotePropertyName url -NotePropertyValue $RequestAccessUrl }
                $policy
            }
        }

        Mock -CommandName Get-DevOpsOrganizationPolicyMap -MockWith {
            return @(
                @{ PropertyName = 'EnableIPConditionalAccessPolicyValidation'; PolicyName = 'Policy.EnforceAADConditionalAccess' }
                @{ PropertyName = 'LogAuditEvents';                            PolicyName = 'Policy.LogAuditEvents' }
                @{ PropertyName = 'AllowTeamAdminsToInviteUsers';              PolicyName = 'Policy.AllowTeamAdminsInvitationsAccessToken' }
                @{ PropertyName = 'EnableRequestAccess';                       PolicyName = 'Policy.AllowRequestAccessToken' }
                @{ PropertyName = 'EnableArtifactsFeedUpstreamProtection';     PolicyName = 'Policy.ArtifactsExternalPackageProtectionToken' }
            )
        }
    }

    Context "when settings can be retrieved and match" {
        BeforeEach {
            Mock -CommandName Get-DevOpsOrganizationSettings -MockWith {
                return @{
                    'Microsoft.VisualStudio.Services.EnablePublicProjects' = 'false'
                }
            }
            Mock -CommandName Get-DevOpsOrganizationPolicy -MockWith { New-LivePolicyList }
        }

        It "returns status Unchanged when AllowPublicProjects matches" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -AllowPublicProjects $false
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when AllowPublicProjects differs" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -AllowPublicProjects $true
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'AllowPublicProjects'
        }

        It "populates liveCache" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization'
            $result.liveCache | Should -Not -BeNullOrEmpty
        }
    }

    Context "when settings API call fails" {
        BeforeEach {
            Mock -CommandName Get-DevOpsOrganizationSettings -MockWith {
                throw "API unavailable"
            }
            Mock -CommandName Get-DevOpsOrganizationPolicy -MockWith { New-LivePolicyList }
        }

        It "returns status Error" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization'
            $result.status | Should -Be 'Error'
        }
    }

    Context "when organization policies are read" {
        BeforeEach {
            Mock -CommandName Get-DevOpsOrganizationSettings -MockWith {
                return @{ 'Microsoft.VisualStudio.Services.EnablePublicProjects' = 'false' }
            }
            Mock -CommandName Get-DevOpsOrganizationPolicy -MockWith {
                New-LivePolicyList -Values @{
                    'Policy.LogAuditEvents'           = $true
                    'Policy.AllowRequestAccessToken'  = $true
                } -RequestAccessUrl 'https://contoso.example/request'
            }
        }

        It "reads all policies in one call rather than one call per policy" {
            $null = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization'
            Assert-MockCalled -CommandName Get-DevOpsOrganizationPolicy -Exactly -Times 1
        }

        It "returns status Unchanged when all managed policy properties match" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents 'true' -AllowTeamAdminsToInviteUsers 'false'
            $result.status | Should -Be 'Unchanged'
        }

        It "accepts a boolean-looking value in any case" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents 'True'
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when LogAuditEvents differs" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents 'false'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'LogAuditEvents'
        }

        It "does not compare AllowTeamAdminsToInviteUsers when not bound" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents 'true'
            $result.propertiesChanged | Should -Not -Contain 'AllowTeamAdminsToInviteUsers'
        }

        It "does not compare any policy passed as '' (unmanaged), as the resource base class passes them" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' `
                -EnableIPConditionalAccessPolicyValidation '' -LogAuditEvents '' -AllowTeamAdminsToInviteUsers '' `
                -EnableRequestAccess '' -RequestAccessUrl '' -EnableArtifactsFeedUpstreamProtection ''
            $result.status | Should -Be 'Unchanged'
            $result.propertiesChanged | Should -BeNullOrEmpty
        }

        It "returns status Changed when RequestAccessUrl differs and EnableRequestAccess is 'true'" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -EnableRequestAccess 'true' -RequestAccessUrl 'https://contoso.example/other'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'RequestAccessUrl'
        }

        It "does not compare RequestAccessUrl when EnableRequestAccess is unmanaged" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -EnableRequestAccess '' -RequestAccessUrl 'https://contoso.example/other'
            $result.propertiesChanged | Should -Not -Contain 'RequestAccessUrl'
        }

        It "does not compare RequestAccessUrl when it is empty" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -EnableRequestAccess 'true' -RequestAccessUrl ''
            $result.status | Should -Be 'Unchanged'
        }

        It "reports every managed policy as 'true' or 'false' on the result" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization'
            $result.LogAuditEvents | Should -BeExactly 'true'
            $result.AllowTeamAdminsToInviteUsers | Should -BeExactly 'false'
            $result.EnableRequestAccess | Should -BeExactly 'true'
            $result.EnableIPConditionalAccessPolicyValidation | Should -BeExactly 'false'
            $result.EnableArtifactsFeedUpstreamProtection | Should -BeExactly 'false'
            $result.RequestAccessUrl | Should -Be 'https://contoso.example/request'
        }
    }

    Context "when the policy values come back in other shapes" {
        BeforeEach {
            Mock -CommandName Get-DevOpsOrganizationSettings -MockWith {
                return @{ 'Microsoft.VisualStudio.Services.EnablePublicProjects' = 'false' }
            }
        }

        It "prefers effectiveValue over value" {
            Mock -CommandName Get-DevOpsOrganizationPolicy -MockWith {
                New-LivePolicyList | ForEach-Object {
                    if ($_.name -eq 'Policy.LogAuditEvents') { $_.value = $false; $_.effectiveValue = $true }
                    $_
                }
            }
            (Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization').LogAuditEvents | Should -BeExactly 'true'
        }

        It "falls back to value when there is no effectiveValue" {
            Mock -CommandName Get-DevOpsOrganizationPolicy -MockWith {
                New-LivePolicyList | ForEach-Object {
                    if ($_.name -eq 'Policy.LogAuditEvents') { [PSCustomObject]@{ name = $_.name; value = $true } } else { $_ }
                }
            }
            (Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization').LogAuditEvents | Should -BeExactly 'true'
        }

        It "reads string values" {
            Mock -CommandName Get-DevOpsOrganizationPolicy -MockWith {
                New-LivePolicyList | ForEach-Object {
                    if ($_.name -eq 'Policy.LogAuditEvents') { $_.value = 'True'; $_.effectiveValue = 'True' }
                    $_
                }
            }
            (Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization').LogAuditEvents | Should -BeExactly 'true'
        }

        It "returns status Error when a managed policy is missing from the service response" {
            Mock -CommandName Get-DevOpsOrganizationPolicy -MockWith {
                New-LivePolicyList | Where-Object { $_.name -ne 'Policy.ArtifactsExternalPackageProtectionToken' }
            }
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -EnableArtifactsFeedUpstreamProtection 'true'
            $result.status | Should -Be 'Error'
            Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -like '*Policy.ArtifactsExternalPackageProtectionToken*' }
        }
    }

    Context "when the organization policies cannot be read" {
        BeforeEach {
            Mock -CommandName Get-DevOpsOrganizationSettings -MockWith {
                return @{ 'Microsoft.VisualStudio.Services.EnablePublicProjects' = 'false' }
            }
            Mock -CommandName Get-DevOpsOrganizationPolicy -MockWith { throw 'policy read boom' }
        }

        It "asks for exactly the mapped policies, so the per-policy route can be used" {
            $null = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization'
            Assert-MockCalled -CommandName Get-DevOpsOrganizationPolicy -Times 1 -Exactly -ParameterFilter {
                ($PolicyName -join ',') -eq 'Policy.EnforceAADConditionalAccess,Policy.LogAuditEvents,Policy.AllowTeamAdminsInvitationsAccessToken,Policy.AllowRequestAccessToken,Policy.ArtifactsExternalPackageProtectionToken'
            }
        }

        It "still compares the host settings, with a warning, when no policy is configured" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -AllowPublicProjects $false
            $result.status | Should -Be 'Unchanged'
            Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -like '*none is configured*policy read boom*' }
        }

        It "reports a host setting change when no policy is configured" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -AllowPublicProjects $true
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'AllowPublicProjects'
        }

        It "returns status Error when a policy is configured" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents 'true'
            $result.status | Should -Be 'Error'
            Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -like '*Could not retrieve settings*policy read boom*' }
        }

        It "returns status Error when only RequestAccessUrl is configured" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -RequestAccessUrl 'https://contoso.example/request'
            $result.status | Should -Be 'Error'
        }
    }
}
