# Requires -Module Pester -Version 5.0.0

# Test if the class is defined
if ($null -eq $Global:ClassesLoaded)
{
    # Attempt to find the root of the repository
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    # Load the Dependencies
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}

# Always reload Enums+Classes into this file's own scope. Pester rebinds each test/block's
# session state for isolation, which can leave classes loaded elsewhere (e.g. by the
# orchestrator above) unresolvable - causing intermittent "Could not find type [X]" failures.
$RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
. "$RepositoryRoot\tests\Unit\Modules\TestHelpers\Import-ClassesAndEnums.ps1" -RepositoryRoot $RepositoryRoot

Describe 'AuthenticationToken Class' -Tag "Unit", "Authentication" {
    Context 'ConvertFromSecureString Method' {
        It 'Should convert a SecureString to a String correctly' {
            # Arrange
            $secureString = ConvertTo-SecureString "TestPassword" -AsPlainText -Force
            $authToken = [AuthenticationToken]::new()

            # Act
            $result = $authToken.ConvertFromSecureString($secureString)

            # Assert
            $result | Should -Be "TestPassword"
        }
    }

    Context 'TestCallStack Method' {
        It 'Should return true if the calling function is found in the call stack' {
            # Arrange
            function Test-CallStackFunction
            {
                $authToken = [AuthenticationToken]::new()
                return $authToken.TestCallStack('Test-CallStackFunction')
            }

            # Act
            $result = Test-CallStackFunction

            # Assert
            $result | Should -Be $true
        }

        It 'Should return false if the calling function is not found in the call stack' {
            # Arrange
            $authToken = [AuthenticationToken]::new()

            # Act
            $result = $authToken.TestCallStack('NonExistentFunction')

            # Assert
            $result | Should -Be $false
        }
    }

    Context 'TestCaller Method' {
        It 'Should throw an exception if called from an unauthorized function' {
            # Arrange
            $authToken = [AuthenticationToken]::new()

            # Act & Assert
            { $authToken.TestCaller() } | Should -Throw "*The Get() method can only be called*"
        }
    }

    Context 'Get Method' {
        It 'Should return the access token when called from an authorized function' {
            # Arrange
            function Invoke-AzDevOpsApiRestMethod
            {
                $authToken = [AuthenticationToken]::new()
                $authToken.access_token = ConvertTo-SecureString "TestToken" -AsPlainText -Force
                return $authToken.Get()
            }

            # Act
            $result = Invoke-AzDevOpsApiRestMethod

            # Assert
            $result | Should -Be "TestToken"
        }

        It 'Should throw an exception when called from an unauthorized function' {
            # Arrange
            $authToken = [AuthenticationToken]::new()

            # Act & Assert
            { $authToken.Get() } | Should -Throw "*The Get() method can only be called*"
        }
    }
}
