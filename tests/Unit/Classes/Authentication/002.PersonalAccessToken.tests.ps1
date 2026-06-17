$currentFile = $MyInvocation.MyCommand.Path

Describe 'PersonalAccessToken' -Tag "Unit", "Authentication" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath '002.PersonalAccessToken.tests.ps1'
        }

        $helperModule = Join-Path $PSScriptRoot '..\..\Modules\TestHelpers\CommonTestFunctions.psm1'
        if (Test-Path $helperModule) { Import-Module $helperModule -Force }

        Get-FunctionItem @() | Out-Null
        Import-Enums | ForEach-Object { . $_.FullName }
        . (Get-FunctionItem 'ConvertTo-Base64String.ps1').FullName
        . (Get-ClassFilePath '001.AuthenticationToken')
        . (Get-ClassFilePath '002.PersonalAccessToken')
    }

    Context 'Class - Constructor with String Parameter' {
        It 'Should initialize with a string personal access token' {
            $pat = [PersonalAccessToken]::new("TestToken")
            $pat.tokenType | Should -Be 'PersonalAccessToken'
            $pat.ConvertFromSecureString($pat.access_token) | Should -Be "OlRlc3RUb2tlbg=="
        }
    }

    Context 'Class - Constructor with SecureString Parameter' {
        It 'Should initialize with a secure string personal access token' {
            $secureStringPAT = ConvertTo-SecureString "TestSecureToken" -AsPlainText -Force
            $pat = [PersonalAccessToken]::new($secureStringPAT)
            $pat.tokenType | Should -Be 'PersonalAccessToken'
            $pat.access_token | Should -Be $secureStringPAT
        }
    }

    Context 'Class - isExpired Method' {
        It 'Should always return false' {
            $pat = [PersonalAccessToken]::new("TestToken")
            $pat.isExpired() | Should -Be $false
        }
    }

    Context 'New-PersonalAccessToken Function' {
        It 'Should create a new PersonalAccessToken object with a string token' {
            $pat = New-PersonalAccessToken -PersonalAccessToken "TestToken"
            $pat.tokenType | Should -Be 'PersonalAccessToken'
            $pat.ConvertFromSecureString($pat.access_token) | Should -Be "OlRlc3RUb2tlbg=="
        }

        It 'Should create a new PersonalAccessToken object with a secure string token' {
            $secureStringPAT = ConvertTo-SecureString "TestSecureToken" -AsPlainText -Force
            $pat = New-PersonalAccessToken -SecureStringPersonalAccessToken $secureStringPAT
            $pat.tokenType | Should -Be 'PersonalAccessToken'
            $pat.access_token | Should -Be $secureStringPAT
        }

        It 'Should throw an error if no token is provided' {
            { New-PersonalAccessToken } | Should -Throw "Error. A Personal Access Token or SecureString Personal Access Token must be provided."
        }
    }
}
