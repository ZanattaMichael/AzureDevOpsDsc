$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzCliToken Tests" -Tags "Unit", "Authentication" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzCliToken.tests.ps1'
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

        $futureExpiry    = (Get-Date).AddHours(1).ToString('yyyy-MM-dd HH:mm:ss.ffffff')
        $validCLIJson    = (@{ accessToken = "fake-cli-token"; expiresOn = $futureExpiry; tokenType = "Bearer" } | ConvertTo-Json)

        Mock -CommandName New-AzureCliToken -MockWith {
            return [PSCustomObject]@{ tokenType = 'AzureCLI' }
        }

        Mock -CommandName Test-AzToken -MockWith { return $true }

        $Global:DSCAZDO_OrganizationName = "TestOrg"
    }

    BeforeEach {
        $script:LastExitCode = 0
    }

    Context "When az CLI is not installed" {

        BeforeAll {
            Mock -CommandName Get-Command -MockWith { return $null } -ParameterFilter { $Name -eq 'az' }
        }

        It "Should throw a descriptive error" {
            { Get-AzCliToken -OrganizationName "TestOrg" } |
                Should -Throw "*Azure CLI*not installed*"
        }
    }

    Context "When az CLI is installed and returns a valid token" {

        BeforeAll {
            Mock -CommandName Get-Command -MockWith { return [PSCustomObject]@{ Name = 'az' } } -ParameterFilter { $Name -eq 'az' }
            Mock -CommandName Invoke-AzCLICommand -MockWith {
                $global:LASTEXITCODE = 0
                return $validCLIJson
            }
        }

        It "Should return the token object" {
            $result = Get-AzCliToken -OrganizationName "TestOrg"
            $result | Should -Not -BeNullOrEmpty
            Assert-MockCalled -CommandName Invoke-AzCLICommand -Times 1
            Assert-MockCalled -CommandName New-AzureCliToken -Times 1
        }
    }

    Context "When az CLI returns a non-zero exit code" {

        BeforeAll {
            Mock -CommandName Get-Command -MockWith { return [PSCustomObject]@{ Name = 'az' } } -ParameterFilter { $Name -eq 'az' }
            Mock -CommandName Invoke-AzCLICommand -MockWith {
                $global:LASTEXITCODE = 1
                return "ERROR: Please run 'az login'"
            }
        }

        It "Should throw an error with the exit code" {
            { Get-AzCliToken -OrganizationName "TestOrg" } |
                Should -Throw "*non-zero exit code*"
        }
    }

    Context "When az CLI returns output with null accessToken" {

        BeforeAll {
            Mock -CommandName Get-Command -MockWith { return [PSCustomObject]@{ Name = 'az' } } -ParameterFilter { $Name -eq 'az' }
            Mock -CommandName Invoke-AzCLICommand -MockWith {
                $global:LASTEXITCODE = 0
                return (@{ accessToken = $null; expiresOn = "2025-01-01 12:00:00.000000"; tokenType = "Bearer" } | ConvertTo-Json)
            }
        }

        It "Should throw an error about missing access token" {
            { Get-AzCliToken -OrganizationName "TestOrg" } |
                Should -Throw "*Access token not returned*"
        }
    }

    Context "With -Verify switch" {

        BeforeAll {
            Mock -CommandName Get-Command -MockWith { return [PSCustomObject]@{ Name = 'az' } } -ParameterFilter { $Name -eq 'az' }
            Mock -CommandName Invoke-AzCLICommand -MockWith {
                $global:LASTEXITCODE = 0
                return $validCLIJson
            }
        }

        It "Should call Test-AzToken when -Verify is set" {
            Mock -CommandName Test-AzToken -MockWith { return $true }
            Get-AzCliToken -OrganizationName "TestOrg" -Verify
            Assert-MockCalled -CommandName Test-AzToken -Times 1
        }

        It "Should throw when -Verify and Test-AzToken returns false" {
            Mock -CommandName Test-AzToken -MockWith { return $false }
            { Get-AzCliToken -OrganizationName "TestOrg" -Verify } |
                Should -Throw "*Token verification failed*"
        }
    }
}
