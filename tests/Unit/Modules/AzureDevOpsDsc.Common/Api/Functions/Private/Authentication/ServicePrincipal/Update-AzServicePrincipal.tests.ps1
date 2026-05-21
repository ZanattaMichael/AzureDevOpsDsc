$currentFile = $MyInvocation.MyCommand.Path

Describe "Update-AzServicePrincipal Tests" -Tags "Unit", "Authentication" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Update-AzServicePrincipal.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        Import-Enums | ForEach-Object { . $_.FullName }

        . (Get-ClassFilePath '001.AuthenticationToken')
        . (Get-ClassFilePath '002.PersonalAccessToken')
        . (Get-ClassFilePath '003.ManagedIdentityToken')
        . (Get-ClassFilePath '003b.ServicePrincipalToken')

        Mock -CommandName Get-AzServicePrincipalToken -MockWith { return "newToken" }
    }

    BeforeEach {
        $Global:DSCAZDO_OrganizationName    = $null
        $Global:DSCAZDO_AuthenticationToken = $null
    }

    Context "When the Organization Name is not set" {

        It "Should throw an error" {
            $Global:DSCAZDO_OrganizationName = $null
            { Update-AzServicePrincipal } | Should -Throw "*Organization Name is not set*"
        }
    }

    Context "When no existing token is set" {

        It "Should throw an error about missing token" {
            $Global:DSCAZDO_OrganizationName    = "TestOrg"
            $Global:DSCAZDO_AuthenticationToken = $null
            { Update-AzServicePrincipal } | Should -Throw "*No existing authentication token found*"
        }
    }

    Context "When the Organization Name and token are set" {

        BeforeEach {
            $Global:DSCAZDO_OrganizationName = "TestOrg"

            # Create a mock token that exposes the required properties
            $mockToken = [PSCustomObject]@{
                tenantId = "mock-tenant"
                clientId = "mock-client"
            }
            $mockToken | Add-Member -MemberType ScriptMethod -Name GetClientSecret -Value { return "mock-secret" }
            $Global:DSCAZDO_AuthenticationToken = $mockToken
        }

        It "Should clear the existing token" {
            Update-AzServicePrincipal
            # After call, global was set to "newToken" by mock (via assignment in function)
            $Global:DSCAZDO_AuthenticationToken | Should -Be "newToken"
        }

        It "Should call Get-AzServicePrincipalToken with the correct credentials" {
            Mock -CommandName Get-AzServicePrincipalToken -MockWith { return "newToken" }

            Update-AzServicePrincipal

            Assert-MockCalled -CommandName Get-AzServicePrincipalToken -Times 1 -ParameterFilter {
                $TenantId -eq "mock-tenant" -and $ClientId -eq "mock-client" -and $ClientSecret -eq "mock-secret"
            }
        }

        It "Should return the new token" {
            Mock -CommandName Get-AzServicePrincipalToken -MockWith { return "refreshedToken" }

            $result = Update-AzServicePrincipal
            $result | Should -Be "refreshedToken"
        }
    }
}
