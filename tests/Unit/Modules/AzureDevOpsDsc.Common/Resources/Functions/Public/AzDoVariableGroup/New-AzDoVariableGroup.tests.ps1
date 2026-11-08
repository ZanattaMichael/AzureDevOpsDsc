$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoVariableGroup Tests' -Tag "Unit", "VariableGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoVariableGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        # The variable normalizer decides what is sent; load it rather than mock it.
        . (Get-FunctionItem 'ConvertTo-AzDoVariableGroupVariables.ps1').FullName

        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsVariableGroup   -MockWith { return @{ id = 'new-vg-id'; name = 'TestVG' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName List-DevOpsVariableGroups -MockWith { return $null }

    }

    Context 'When the group is read back after the write' {

        BeforeEach {
            Mock -CommandName List-DevOpsVariableGroups -MockWith {
                return @(
                    [PSCustomObject]@{ id = 'other-id'; name = 'Other'; description = 'not this one' }
                    [PSCustomObject]@{ id = 'new-vg-id'; name = 'TestVG'; description = 'as stored' }
                )
            }
        }

        It 'Should cache the group as the API reads it back, not the write response' {
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Description 'as stored'

            Assert-MockCalled -CommandName List-DevOpsVariableGroups -Exactly 1 -ParameterFilter {
                $ProjectName -eq 'TestProject' -and $ApiUri -eq 'https://dev.azure.com/TestOrganization'
            }
            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestVG' -and $Value.id -eq 'new-vg-id' -and $Value.description -eq 'as stored'
            }
        }

        It 'Should fall back to the write response when the read-back does not list the group' {
            Mock -CommandName List-DevOpsVariableGroups -MockWith { return $null }

            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestVG' -and $Value.id -eq 'new-vg-id'
            }
        }
    }

    Context 'When creating a new variable group successfully' {

        It 'Should call New-DevOpsVariableGroup with required parameters' {
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName New-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $ProjectName -eq 'TestProject' -and
                $VariableGroupName -eq 'TestVG'
            }
        }

        It 'Should call Add-CacheItem with the composite key' {
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestVG' -and $Type -eq 'LiveVariableGroups'
            }
        }

        It 'Should call Export-CacheObject for LiveVariableGroups' {
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Export-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LiveVariableGroups'
            }
        }

        It 'Should call Refresh-CacheObject for LiveVariableGroups' {
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LiveVariableGroups'
            }
        }

    }

    Context 'When optional Variables hashtable is provided' {

        It 'Should pass Variables to New-DevOpsVariableGroup' {
            $vars = @{ myVar = 'myValue' }
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Variables $vars

            Assert-MockCalled -CommandName New-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $Variables -ne $null
            }
        }

        It 'Should normalize a flat variable to the API shape' {
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Variables @{ APP_ENV = 'production' }

            Assert-MockCalled -CommandName New-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $Variables.APP_ENV.value -eq 'production' -and $Variables.APP_ENV.isSecret -eq $false
            }
        }

        It 'Should pass a secret variable through with isSecret true' {
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Variables @{
                APP_KEY = @{ value = 'p@ssw0rd'; isSecret = $true }
            }

            Assert-MockCalled -CommandName New-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $Variables.APP_KEY.value -eq 'p@ssw0rd' -and $Variables.APP_KEY.isSecret -eq $true
            }
        }

        It 'Should pass an empty set when no Variables are given' {
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName New-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $null -ne $Variables -and $Variables.Count -eq 0
            }
        }

    }

    Context 'When VariableGroupType is specified' {

        It 'Should forward the custom type to New-DevOpsVariableGroup' {
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -VariableGroupType 'AzureKeyVault'

            Assert-MockCalled -CommandName New-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $Type -eq 'AzureKeyVault'
            }
        }

    }

}
