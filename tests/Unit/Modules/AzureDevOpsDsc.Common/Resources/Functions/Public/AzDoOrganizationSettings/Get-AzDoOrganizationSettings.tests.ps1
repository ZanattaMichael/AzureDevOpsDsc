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
            Mock -CommandName Get-DevOpsOrganizationPolicy -MockWith { return @{ value = $false; url = '' } }
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
            Mock -CommandName Get-DevOpsOrganizationPolicy -MockWith { return @{ value = $false; url = '' } }
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
                switch ($PolicyName)
                {
                    'Policy.LogAuditEvents'                          { return @{ value = $true } }
                    'Policy.AllowTeamAdminsInvitationsAccessToken'   { return @{ value = $false } }
                    'Policy.AllowRequestAccessToken'                 { return @{ value = $true; url = 'https://contoso.example/request' } }
                    default                                          { return @{ value = $false } }
                }
            }
        }

        It "returns status Unchanged when all bound policy properties match" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents $true -AllowTeamAdminsToInviteUsers $false
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when LogAuditEvents differs" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents $false
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'LogAuditEvents'
        }

        It "does not compare AllowTeamAdminsToInviteUsers when not bound" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -LogAuditEvents $true
            $result.propertiesChanged | Should -Not -Contain 'AllowTeamAdminsToInviteUsers'
        }

        It "returns status Changed when RequestAccessUrl differs and EnableRequestAccess is true" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -EnableRequestAccess $true -RequestAccessUrl 'https://contoso.example/other'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'RequestAccessUrl'
        }

        It "does not compare RequestAccessUrl when EnableRequestAccess is not bound" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -RequestAccessUrl 'https://contoso.example/other'
            $result.propertiesChanged | Should -Not -Contain 'RequestAccessUrl'
        }

        It "populates all managed policy names on the result" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization'
            $result.LogAuditEvents | Should -Be $true
            $result.AllowTeamAdminsToInviteUsers | Should -Be $false
            $result.EnableRequestAccess | Should -Be $true
            $result.RequestAccessUrl | Should -Be 'https://contoso.example/request'
        }
    }
}
