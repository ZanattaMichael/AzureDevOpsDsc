$currentFile = $MyInvocation.MyCommand.Path

Describe "Update-AzWorkloadIdentityFederation Tests" -Tags "Unit", "Authentication" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Update-AzWorkloadIdentityFederation.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        Mock -CommandName Get-AzWorkloadIdentityFederationToken -MockWith { return "newToken" }
    }

    BeforeEach {
        $Global:DSCAZDO_OrganizationName    = $null
        $Global:DSCAZDO_AuthenticationToken = $null
    }

    Context "When the Organization Name is not set" {

        It "Should throw an error" {
            { Update-AzWorkloadIdentityFederation } | Should -Throw "*Organization Name is not set*"
        }
    }

    Context "When no existing token is set" {

        It "Should throw an error about missing token" {
            $Global:DSCAZDO_OrganizationName = "TestOrg"
            { Update-AzWorkloadIdentityFederation } | Should -Throw "*No existing authentication token found*"
        }
    }

    Context "When the source is 'File'" {

        BeforeEach {
            $Global:DSCAZDO_OrganizationName = "TestOrg"
            $Global:DSCAZDO_AuthenticationToken = [PSCustomObject]@{
                tenantId              = "mock-tenant"
                clientId              = "mock-client"
                federatedTokenSource  = "File"
                federatedTokenFile    = "/token"
            }
        }

        It "Should call Get-AzWorkloadIdentityFederationToken with the stored file path" {
            Mock -CommandName Get-AzWorkloadIdentityFederationToken -MockWith { return "newToken" }

            Update-AzWorkloadIdentityFederation

            Assert-MockCalled -CommandName Get-AzWorkloadIdentityFederationToken -Times 1 -ParameterFilter {
                $TenantId -eq "mock-tenant" -and $ClientId -eq "mock-client" -and $FederatedTokenFile -eq "/token"
            }
        }

        It "Should return the new token" {
            Mock -CommandName Get-AzWorkloadIdentityFederationToken -MockWith { return "refreshedToken" }
            $result = Update-AzWorkloadIdentityFederation
            $result | Should -Be "refreshedToken"
        }
    }

    Context "When the source is 'GitHubActions'" {

        BeforeEach {
            $Global:DSCAZDO_OrganizationName = "TestOrg"
            $Global:DSCAZDO_AuthenticationToken = [PSCustomObject]@{
                tenantId              = "mock-tenant"
                clientId              = "mock-client"
                federatedTokenSource  = "GitHubActions"
                federatedTokenFile    = ""
            }
        }

        It "Should call Get-AzWorkloadIdentityFederationToken with -GitHubActions" {
            Mock -CommandName Get-AzWorkloadIdentityFederationToken -MockWith { return "newToken" }

            Update-AzWorkloadIdentityFederation

            Assert-MockCalled -CommandName Get-AzWorkloadIdentityFederationToken -Times 1 -ParameterFilter {
                $GitHubActions.IsPresent -and $TenantId -eq "mock-tenant"
            }
        }
    }

    Context "When the source is 'Manual'" {

        BeforeEach {
            $Global:DSCAZDO_OrganizationName = "TestOrg"
            $Global:DSCAZDO_AuthenticationToken = [PSCustomObject]@{
                tenantId              = "mock-tenant"
                clientId              = "mock-client"
                federatedTokenSource  = "Manual"
                federatedTokenFile    = ""
            }
        }

        It "Should throw a clear error explaining it cannot be refreshed" {
            { Update-AzWorkloadIdentityFederation } | Should -Throw "*cannot be refreshed automatically*"
        }
    }
}
