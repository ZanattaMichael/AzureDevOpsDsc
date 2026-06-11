$currentFile = $MyInvocation.MyCommand.Path

Describe 'Clear-AzDoACE Tests' -Tag "Unit", "ACE" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Clear-AzDoACE.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # Mock the Get-AzDevOpsApiVersion function to return a fixed API version
        Mock -CommandName Get-AzDevOpsApiVersion { return "6.0" }

        # Mock the Invoke-AzDevOpsApiRestMethod function to simulate API behavior
        Mock -CommandName Invoke-AzDevOpsApiRestMethod { Write-Output "API Called" }
        Mock -CommandName Write-Warning

    }


    # Test case: Ensure the function handles valid input correctly
    It 'Should call Invoke-AzDevOpsApiRestMethod with correct parameters' {
        # Arrange
        $OrganizationName = "MyOrg"
        $SecurityNamespaceID = "12345"
        $DifferenceACLs = @{
            token = @{ _token = "sampleToken" }
            aces = @{
                Identity = @{
                    value = @{
                        ACLIdentity = @{
                            descriptor = @("Descriptor1", "Descriptor2")
                        }
                    }
                }
            }
        }

        # Act
        Clear-AzDoACE -OrganizationName $OrganizationName -SecurityNamespaceID $SecurityNamespaceID -DifferenceACLs $DifferenceACLs

        # Assert
        Assert-MockCalled -Exactly 1 -CommandName Invoke-AzDevOpsApiRestMethod -Scope It
    }

    # Test case: Handle empty subdescriptors
    It 'Should not call Invoke-AzDevOpsApiRestMethod if there are no subdescriptors' {
        # Arrange
        $OrganizationName = "MyOrg"
        $SecurityNamespaceID = "12345"
        $DifferenceACLs = @{
            token = @{ _token = "sampleToken" }
            aces = @{
                Identity = @{
                    value = @{
                        ACLIdentity = @{
                            descriptor = @()
                        }
                    }
                }
            }
        }

        # Act
        Clear-AzDoACE -OrganizationName $OrganizationName -SecurityNamespaceID $SecurityNamespaceID -DifferenceACLs $DifferenceACLs

        # Assert
        Assert-MockCalled -Exactly 0 -CommandName Invoke-AzDevOpsApiRestMethod -Scope It
    }

    # Test case: Ensure error handling works
    It 'Should handle exceptions gracefully and output error message' {
        # Arrange
        Mock Invoke-AzDevOpsApiRestMethod { throw "API Call Failed" }
        Mock Write-Error

        $OrganizationName = "MyOrg"
        $SecurityNamespaceID = "12345"
        $DifferenceACLs = @{
            token = @{ _token = "sampleToken" }
            aces = @{
                Identity = @{
                    value = @{
                        ACLIdentity = @{
                            descriptor = @("Descriptor1")
                        }
                    }
                }
            }
        }

        # Capture error output
        { Clear-AzDoACE -OrganizationName $OrganizationName -SecurityNamespaceID $SecurityNamespaceID -DifferenceACLs $DifferenceACLs } | Should -Not -Throw

        # Assert
        Assert-MockCalled -Exactly 1 -CommandName Write-Error -Scope It
    }
}
