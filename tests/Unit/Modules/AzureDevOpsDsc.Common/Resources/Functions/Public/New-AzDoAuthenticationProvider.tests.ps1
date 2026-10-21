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
        Mock -CommandName Get-AzWorkloadIdentityFederationToken -MockWith { return "mockedWIFToken" }
        Mock -CommandName Get-AzDoCacheObjects -MockWith { return @() }
        Mock -CommandName Get-Command
        Mock -CommandName Initialize-CacheObject
        Mock -CommandName Export-Clixml
        Mock -CommandName Protect-AzDoCachePath
        Mock -CommandName Test-AzDoIsWindows -MockWith { return $true }
        Mock -CommandName Write-Warning

    }

    BeforeEach {
        # TestDrive rather than a C:\ path so the Join-Path calls also work on Linux.
        $ENV:AZDODSC_CACHE_DIRECTORY = $TestDrive
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

    Context "Default parameter set" {

        It "Is the SecureString Personal Access Token set, so a plain-text secret is never the default" {
            # Get-Command is mocked above, so read the FunctionInfo from the function: drive instead.
            (Get-Item -Path 'function:New-AzDoAuthenticationProvider').DefaultParameterSet | Should -Be 'SecureStringPersonalAccessToken'
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

        It "Should warn that the PAT was passed as plain text and name the SecureString parameter" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -PersonalAccessToken "dummyPat" -NoVerify

            Should -Invoke -CommandName Write-Warning -Exactly 1 -ParameterFilter {
                $Message -like '*plain text*' -and $Message -like '*-SecureStringPersonalAccessToken*'
            }
        }

        It "Should still warn about plain text when isResource is set" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -PersonalAccessToken "dummyPat" -NoVerify -isResource

            Should -Invoke -CommandName Write-Warning -Exactly 1 -ParameterFilter { $Message -like '*plain text*' }
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

        It "Should not warn about plain-text secrets" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -useManagedIdentity -NoVerify

            Should -Invoke -CommandName Write-Warning -Exactly 0 -ParameterFilter { $Message -like '*plain text*' }
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

        It "Should not warn about plain-text secrets" {
            $secureStringPAT = ConvertTo-SecureString "dummySecurePat" -AsPlainText -Force

            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -SecureStringPersonalAccessToken $secureStringPAT

            Should -Invoke -CommandName Write-Warning -Exactly 0 -ParameterFilter { $Message -like '*plain text*' }
        }

        It "Should be selected when the PAT is passed positionally as a SecureString through the alias" {
            $secureStringPAT = ConvertTo-SecureString "dummySecurePat" -AsPlainText -Force

            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -SecureStringPAT $secureStringPAT

            Assert-MockCalled -CommandName Set-AzPersonalAccessToken -Exactly 1 -ParameterFilter { $null -ne $SecureStringPersonalAccessToken }
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

        It "Should warn that the client secret was passed as plain text and name the SecureString parameter" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -ClientSecret "secret" -NoVerify

            Should -Invoke -CommandName Write-Warning -Exactly 1 -ParameterFilter {
                $Message -like '*plain text*' -and $Message -like '*-SecureStringClientSecret*'
            }
        }

        It "Should accept SecureString client secret" {
            $securePwd = ConvertTo-SecureString "secret" -AsPlainText -Force
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -SecureStringClientSecret $securePwd -NoVerify

            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedSPToken"
            Assert-MockCalled -CommandName Get-AzServicePrincipalToken -Exactly 1
        }

        It "Should not warn about plain-text secrets when the client secret is a SecureString" {
            $securePwd = ConvertTo-SecureString "secret" -AsPlainText -Force
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -SecureStringClientSecret $securePwd -NoVerify

            Should -Invoke -CommandName Write-Warning -Exactly 0 -ParameterFilter { $Message -like '*plain text*' }
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

    Context "Using WorkloadIdentityFederationFile parameter set" {

        It "Should set the global authentication token without verification" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -FederatedTokenFile "/token" -NoVerify

            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedWIFToken"
            Assert-MockCalled -CommandName Get-AzWorkloadIdentityFederationToken -Exactly 1 -ParameterFilter { $FederatedTokenFile -eq "/token" }
        }

        It "Should set the global authentication token with verification" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -FederatedTokenFile "/token"

            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedWIFToken"
            Assert-MockCalled -CommandName Get-AzWorkloadIdentityFederationToken -Exactly 1 -ParameterFilter { $Verify }
        }
    }

    Context "Using WorkloadIdentityFederationGitHubActions parameter set" {

        It "Should set the global authentication token without verification" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -useGitHubActionsOIDC -NoVerify

            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedWIFToken"
            Assert-MockCalled -CommandName Get-AzWorkloadIdentityFederationToken -Exactly 1 -ParameterFilter { $GitHubActions.IsPresent }
        }

        It "Should pass a custom GitHubActionsAudience through" {
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -useGitHubActionsOIDC -GitHubActionsAudience "api://Custom" -NoVerify

            Assert-MockCalled -CommandName Get-AzWorkloadIdentityFederationToken -Exactly 1 -ParameterFilter { $GitHubActionsAudience -eq "api://Custom" }
        }
    }

    Context "Using WorkloadIdentityFederationToken parameter set" {

        It "Should set the global authentication token, decrypting the SecureString token" {
            $secureToken = ConvertTo-SecureString "caller-supplied-jwt" -AsPlainText -Force
            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "tenant" -ClientId "client" -FederatedToken $secureToken -NoVerify

            $Global:DSCAZDO_AuthenticationToken | Should -Be "mockedWIFToken"
            Assert-MockCalled -CommandName Get-AzWorkloadIdentityFederationToken -Exactly 1 -ParameterFilter { $FederatedToken -eq "caller-supplied-jwt" }
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

    Context "Cache directory and settings file permissions" {

        BeforeEach {
            $script:expectedSettingsPath = Join-Path -Path $TestDrive -ChildPath 'ModuleSettings.clixml'
        }

        It "Should restrict the cache directory and then the settings file after exporting" {
            $secureStringPAT = ConvertTo-SecureString "dummySecurePat" -AsPlainText -Force

            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -SecureStringPersonalAccessToken $secureStringPAT

            Should -Invoke -CommandName Protect-AzDoCachePath -Exactly 1 -ParameterFilter { $Path -eq $TestDrive }
            Should -Invoke -CommandName Protect-AzDoCachePath -Exactly 1 -ParameterFilter { $Path -eq $script:expectedSettingsPath }
            Should -Invoke -CommandName Protect-AzDoCachePath -Exactly 2
        }

        It "Should not touch any permissions when isResource is set" {
            $secureStringPAT = ConvertTo-SecureString "dummySecurePat" -AsPlainText -Force

            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -SecureStringPersonalAccessToken $secureStringPAT -isResource

            Should -Invoke -CommandName Protect-AzDoCachePath -Exactly 0
        }

        It "Should not restrict the settings file when the export fails" {
            Mock -CommandName Export-Clixml -MockWith { throw 'disk full' }
            $secureStringPAT = ConvertTo-SecureString "dummySecurePat" -AsPlainText -Force

            { New-AzDoAuthenticationProvider -OrganizationName "Contoso" -SecureStringPersonalAccessToken $secureStringPAT } | Should -Throw

            Should -Invoke -CommandName Protect-AzDoCachePath -Exactly 0
        }
    }

    Context "Recoverable credential warning on non-Windows platforms" {

        It "Should warn before exporting when the platform cannot DPAPI-protect the SecureString" {
            Mock -CommandName Test-AzDoIsWindows -MockWith { return $false }
            $secureStringPAT = ConvertTo-SecureString "dummySecurePat" -AsPlainText -Force

            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -SecureStringPersonalAccessToken $secureStringPAT

            Should -Invoke -CommandName Write-Warning -Exactly 1 -ParameterFilter {
                $Message -like '*recoverable form*' -and
                $Message -like '*ModuleSettings.clixml*' -and
                $Message -like '*AZDODSC_CACHE_DIRECTORY*' -and
                $Message -like '*same account*'
            }
        }

        It "Should not warn on Windows" {
            Mock -CommandName Test-AzDoIsWindows -MockWith { return $true }
            $secureStringPAT = ConvertTo-SecureString "dummySecurePat" -AsPlainText -Force

            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -SecureStringPersonalAccessToken $secureStringPAT

            Should -Invoke -CommandName Write-Warning -Exactly 0 -ParameterFilter { $Message -like '*recoverable form*' }
        }

        It "Should not warn when nothing is exported because isResource is set" {
            Mock -CommandName Test-AzDoIsWindows -MockWith { return $false }
            $secureStringPAT = ConvertTo-SecureString "dummySecurePat" -AsPlainText -Force

            New-AzDoAuthenticationProvider -OrganizationName "Contoso" -SecureStringPersonalAccessToken $secureStringPAT -isResource

            Should -Invoke -CommandName Write-Warning -Exactly 0 -ParameterFilter { $Message -like '*recoverable form*' }
            Should -Invoke -CommandName Test-AzDoIsWindows -Exactly 0
        }
    }
}
