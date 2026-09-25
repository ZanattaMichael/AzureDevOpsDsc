$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoOrganizationSettings" -Tag "Unit", "OrganizationSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoOrganizationSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsOrganizationSettings
        Mock -CommandName Set-DevOpsOrganizationPolicy
        Mock -CommandName Write-Warning
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

    Context "when settings are provided" {
        It "calls Set-DevOpsOrganizationSettings" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -AllowPublicProjects $false
            Assert-MockCalled -CommandName Set-DevOpsOrganizationSettings -Exactly -Times 1
        }

        It "does not call Set-DevOpsOrganizationSettings when no bound params besides OrganizationName" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization'
            Assert-MockCalled -CommandName Set-DevOpsOrganizationSettings -Times 0
        }
    }

    Context "when organization policy properties are provided" {
        It "calls Set-DevOpsOrganizationPolicy only for bound policy properties" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents $true
            Assert-MockCalled -CommandName Set-DevOpsOrganizationPolicy -Exactly -Times 1 -ParameterFilter {
                $PolicyName -eq 'Policy.LogAuditEvents' -and $Value -eq $true
            }
        }

        It "does not call Set-DevOpsOrganizationPolicy for unbound policy properties" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents $true
            Assert-MockCalled -CommandName Set-DevOpsOrganizationPolicy -Times 0 -ParameterFilter {
                $PolicyName -eq 'Policy.AllowTeamAdminsInvitationsAccessToken'
            }
        }

        It "passes RequestAccessUrl only when EnableRequestAccess is true" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -EnableRequestAccess $true -RequestAccessUrl 'https://contoso.example/request'
            Assert-MockCalled -CommandName Set-DevOpsOrganizationPolicy -Exactly -Times 1 -ParameterFilter {
                $PolicyName -eq 'Policy.AllowRequestAccessToken' -and $Url -eq 'https://contoso.example/request'
            }
        }

        It "does not pass RequestAccessUrl when EnableRequestAccess is false" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -EnableRequestAccess $false -RequestAccessUrl 'https://contoso.example/request'
            Assert-MockCalled -CommandName Set-DevOpsOrganizationPolicy -Exactly -Times 1 -ParameterFilter {
                $PolicyName -eq 'Policy.AllowRequestAccessToken' -and [String]::IsNullOrEmpty($Url)
            }
        }

        It "writes nothing for policy properties passed as '' (unmanaged), as the resource base class passes them" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization' `
                -EnableIPConditionalAccessPolicyValidation '' -LogAuditEvents '' -AllowTeamAdminsToInviteUsers '' `
                -EnableRequestAccess '' -RequestAccessUrl '' -EnableArtifactsFeedUpstreamProtection ''
            Assert-MockCalled -CommandName Set-DevOpsOrganizationPolicy -Times 0
        }

        It "writes only the managed policy when the others are passed as ''" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization' `
                -EnableIPConditionalAccessPolicyValidation '' -LogAuditEvents '' -AllowTeamAdminsToInviteUsers 'false' `
                -EnableRequestAccess '' -RequestAccessUrl '' -EnableArtifactsFeedUpstreamProtection ''
            Assert-MockCalled -CommandName Set-DevOpsOrganizationPolicy -Exactly -Times 1
            Assert-MockCalled -CommandName Set-DevOpsOrganizationPolicy -Exactly -Times 1 -ParameterFilter {
                $PolicyName -eq 'Policy.AllowTeamAdminsInvitationsAccessToken' -and $Value -eq $false
            }
        }

        It "converts 'true' and 'false' to the boolean the policy API takes" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents 'true' -EnableArtifactsFeedUpstreamProtection 'false'
            Assert-MockCalled -CommandName Set-DevOpsOrganizationPolicy -Exactly -Times 1 -ParameterFilter {
                $PolicyName -eq 'Policy.LogAuditEvents' -and $Value -eq $true
            }
            Assert-MockCalled -CommandName Set-DevOpsOrganizationPolicy -Exactly -Times 1 -ParameterFilter {
                $PolicyName -eq 'Policy.ArtifactsExternalPackageProtectionToken' -and $Value -eq $false
            }
        }

        It "does not pass RequestAccessUrl when it is empty" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -EnableRequestAccess 'true' -RequestAccessUrl ''
            Assert-MockCalled -CommandName Set-DevOpsOrganizationPolicy -Exactly -Times 1 -ParameterFilter {
                $PolicyName -eq 'Policy.AllowRequestAccessToken' -and [String]::IsNullOrEmpty($Url)
            }
        }

        It "does not warn when LogAuditEvents is unmanaged" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents ''
            Assert-MockCalled -CommandName Write-Warning -Times 0
        }

        It "warns when LogAuditEvents is set to false" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents $false
            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1
        }

        It "does not warn when LogAuditEvents is set to true" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents $true
            Assert-MockCalled -CommandName Write-Warning -Times 0
        }
    }
}
