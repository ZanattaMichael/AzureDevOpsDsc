$currentFile = $MyInvocation.MyCommand.Path

Describe "Update-AzCliToken Tests" -Tags "Unit", "Authentication" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Update-AzCliToken.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        Import-Enums | ForEach-Object { . $_.FullName }

        . (Get-ClassFilePath '001.AuthenticationToken')
        . (Get-ClassFilePath '002.PersonalAccessToken')
        . (Get-ClassFilePath '003.ManagedIdentityToken')
        . (Get-ClassFilePath '003d.AzureCliToken')

        Mock -CommandName Get-AzCliToken -MockWith { return "newCliToken" }
    }

    BeforeEach {
        $Global:DSCAZDO_OrganizationName    = $null
        $Global:DSCAZDO_AuthenticationToken = $null
    }

    Context "When the Organization Name is not set" {

        It "Should throw an error" {
            { Update-AzCliToken } | Should -Throw "*Organization Name is not set*"
        }
    }

    Context "When the Organization Name is set" {

        BeforeEach {
            $Global:DSCAZDO_OrganizationName    = "TestOrg"
            $Global:DSCAZDO_AuthenticationToken = "oldCliToken"
        }

        It "Should clear the existing token before refresh" {
            Mock -CommandName Get-AzCliToken -MockWith {
                # Verify global was cleared before this is called
                $Global:DSCAZDO_AuthenticationToken | Should -BeNullOrEmpty
                return "newCliToken"
            }
            Update-AzCliToken
        }

        It "Should call Get-AzCliToken with the correct organization name" {
            Mock -CommandName Get-AzCliToken -MockWith { return "newCliToken" }
            Update-AzCliToken
            Assert-MockCalled -CommandName Get-AzCliToken -Times 1 -ParameterFilter { $OrganizationName -eq "TestOrg" }
        }

        It "Should set and return the new token" {
            Mock -CommandName Get-AzCliToken -MockWith { return "refreshedToken" }
            $result = Update-AzCliToken
            $result | Should -Be "refreshedToken"
            $Global:DSCAZDO_AuthenticationToken | Should -Be "refreshedToken"
        }
    }
}
