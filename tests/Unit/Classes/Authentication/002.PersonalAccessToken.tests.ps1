# Requires -Module Pester -Version 5.0.0

# Test if the class is defined
if ($null -eq $Global:ClassesLoaded)
{
    # Attempt to find the root of the repository
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    # Load the Dependencies
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}

Describe 'PersonalAccessToken Class' {
    Context 'Constructor with String Parameter' {
        It 'Should initialize with a string personal access token' {
            # Arrange
            $personalAccessToken = "TestToken"

            # Act
            $pat = [PersonalAccessToken]::new($personalAccessToken)

            # Assert
            $pat.tokenType | Should -Be 'PersonalAccessToken'
            $pat.ConvertFromSecureString($pat.access_token) | Should -Be "OlRlc3RUb2tlbg=="
        }
    }

    Context 'Constructor with SecureString Parameter' {
        It 'Should initialize with a secure string personal access token' {
            # Arrange
            $secureStringPAT = ConvertTo-SecureString "TestSecureToken" -AsPlainText -Force

            # Act
            $pat = [PersonalAccessToken]::new($secureStringPAT)

            # Assert
            $pat.tokenType | Should -Be 'PersonalAccessToken'
            $pat.access_token | Should -Be $secureStringPAT
        }
    }

    Context 'isExpired Method' {
        It 'Should always return false' {
            # Arrange
            $pat = [PersonalAccessToken]::new("TestToken")

            # Act
            $result = $pat.isExpired()

            # Assert
            $result | Should -Be $false
        }
    }
}

Describe 'New-PersonalAccessToken Function' {
    It 'Should create a new PersonalAccessToken object with a string token' {
        # Arrange
        $personalAccessToken = "TestToken"

        # Act
        $pat = New-PersonalAccessToken -PersonalAccessToken $personalAccessToken

        # Assert
        $pat | Should -BeOfType [PersonalAccessToken]
        $pat.ConvertFromSecureString($pat.access_token) | Should -Be "OlRlc3RUb2tlbg=="
    }

    It 'Should create a new PersonalAccessToken object with a secure string token' {
        # Arrange
        $secureStringPAT = ConvertTo-SecureString "TestSecureToken" -AsPlainText -Force

        # Act
        $pat = New-PersonalAccessToken -SecureStringPersonalAccessToken $secureStringPAT

        # Assert
        $pat | Should -BeOfType [PersonalAccessToken]
        $pat.access_token | Should -Be $secureStringPAT
    }

    It 'Should throw an error if no token is provided' {
        # Act & Assert
        { New-PersonalAccessToken } | Should -Throw "Error. A Personal Access Token or SecureString Personal Access Token must be provided."
    }
}
