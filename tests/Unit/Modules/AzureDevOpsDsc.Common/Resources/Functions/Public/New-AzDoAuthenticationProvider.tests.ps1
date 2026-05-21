$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoAuthenticationProvider" -Tag "Unit", "Public" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        # Set the Organization Name
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoAuthenticationProvider.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Mocking dependencies
        Mock -CommandName Set-AzPersonalAccessToken -MockWith { return "mockedToken" }
        Mock -CommandName Get-AzManagedIdentityToken -MockWith { return "mockedManagedIdentityToken" }
        Mock -CommandName Get-AzServicePrincipalToken -MockWith { return "mockedSPToken" }
        Mock -CommandName Get-AzServicePrincipalCertificateToken -MockWith { return "mockedCertToken" }
        Mock -CommandName Get-AzCliToken -MockWith { return "mockedCLIToken" }
        Mock -CommandName Get-AzDoCacheObjects -MockWith { return @() }
        Mock -CommandName Get-Command
        Mock -CommandName Initialize-CacheObject
        Mock -CommandName Export-Clixml

    }

    BeforeEach {
        $ENV:AZDODSC_CACHE_DIRECTORY = "C:\MockCacheDirectory"
        $Global:DSCAZDO_AuthenticationToken = $null
    }

    AfterEach {
        $ENV:AZDODSC_CACHE_DIRECTORY = $null
        $Global:DSCAZDO_AuthenticationToken = $null
    }

    Context "When AZDODSC_CACHE_DIRECTORY is not set" {

        It "Should throw an error" {
            # Arrange
            $ENV:AZDODSC_CACHE_DIRECTORY = $null

            # Act & Assert
            {
                New-AzDoAuthenticationProvider -OrganizationName "Contoso" -PersonalAccessToken "dummyPat"
            } | Should -Throw "*The Environment Variable 'AZDODSC_CACHE_DIRECTORY' is not set*"
        }
    }

    Context "Using PersonalAccessToken parameter set" {
        It "Should set the global authentication token without verification" {
            # Act
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -PersonalAccessToken "dummyPat" -NoVerify

            # Assert
            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedToken"
            Assert-MockCalled -CommandName Set-AzPersonalAccessToken -Exactly 1
        }

        It "Should set the global authentication token with verification" {
            # Act
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -PersonalAccessToken "dummyPat"

            # Assert
            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedToken"
            Assert-MockCalled -CommandName Set-AzPersonalAccessToken -Exactly 1 -ParameterFilter { $Verify }
        }
    }

    Context "Using ManagedIdentity parameter set" {
        It "Should set the global authentication token without verification" {
            # Act
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -useManagedIdentity -NoVerify

            # Assert
            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedManagedIdentityToken"
            Assert-MockCalled -CommandName Get-AzManagedIdentityToken -Exactly 1
        }

        It "Should set the global authentication token with verification" {
            # Act
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -useManagedIdentity

            # Assert
            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedManagedIdentityToken"
            Assert-MockCalled -CommandName Get-AzManagedIdentityToken -Exactly 1 -ParameterFilter { $Verify }
        }
    }

    Context "Using SecureStringPersonalAccessToken parameter set" {
        It "Should set the global authentication token" {
            # Arrange
            $secureStringPAT = ConvertTo-SecureString "dummySecurePat" -AsPlainText -Force

            # Act
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -SecureStringPersonalAccessToken $secureStringPAT

            # Assert
            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedToken"
            Assert-MockCalled -CommandName Set-AzPersonalAccessToken -Exactly 1
        }
    }

    Context "Using ServicePrincipal parameter set" {

        It "Should set the global authentication token without verification" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -ClientSecret "secret" -NoVerify

            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedSPToken"
            Assert-MockCalled -CommandName Get-AzServicePrincipalToken -Exactly 1
        }

        It "Should set the global authentication token with verification" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -ClientSecret "secret"

            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedSPToken"
            Assert-MockCalled -CommandName Get-AzServicePrincipalToken -Exactly 1 -ParameterFilter { $Verify }
        }

        It "Should accept SecureString client secret" {
            $securePwd = ConvertTo-SecureString "secret" -AsPlainText -Force
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -SecureStringClientSecret $securePwd -NoVerify

            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedSPToken"
            Assert-MockCalled -CommandName Get-AzServicePrincipalToken -Exactly 1
        }
    }

    Context "Using Certificate parameter set (thumbprint)" {

        It "Should set the global authentication token without verification" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -CertificateThumbprint "ABCDEF" -NoVerify

            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedCertToken"
            Assert-MockCalled -CommandName Get-AzServicePrincipalCertificateToken -Exactly 1
        }

        It "Should set the global authentication token with verification" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -CertificateThumbprint "ABCDEF"

            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedCertToken"
            Assert-MockCalled -CommandName Get-AzServicePrincipalCertificateToken -Exactly 1 -ParameterFilter { $Verify }
        }
    }

    Context "Using CertificateFile parameter set (PFX path)" {

        It "Should set the global authentication token" {
            $securePwd = ConvertTo-SecureString "pass" -AsPlainText -Force
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -CertificatePath "/cert.pfx" -CertificatePassword $securePwd -NoVerify

            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedCertToken"
            Assert-MockCalled -CommandName Get-AzServicePrincipalCertificateToken -Exactly 1
        }
    }

    Context "Using AzureCLI parameter set" {

        It "Should set the global authentication token without verification" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -useAzureCLI -NoVerify

            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedCLIToken"
            Assert-MockCalled -CommandName Get-AzCliToken -Exactly 1
        }

        It "Should set the global authentication token with verification" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -useAzureCLI

            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedCLIToken"
            Assert-MockCalled -CommandName Get-AzCliToken -Exactly 1 -ParameterFilter { $Verify }
        }
    }

    Context "Token export functionality" {
        It "Should export token information when isResource is not set" {
            # Act
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -PersonalAccessToken "dummyPat"

            # Assert
            Assert-MockCalled -CommandName Export-Clixml -Exactly 1
        }

        It "Should not export token information when isResource is set" {
            # Act
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -PersonalAccessToken "dummyPat" -isResource

            # Assert
            Assert-MockCalled -CommandName Export-Clixml -Exactly 0
        }
    }
}
