$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoVariableGroup Tests' -Tag "Unit", "VariableGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoVariableGroup.tests.ps1'
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
        Mock -CommandName Set-DevOpsVariableGroup   -MockWith { return @{ id = 'vg-id'; name = 'TestVG' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName List-DevOpsVariableGroups -MockWith { return $null }
        Mock -CommandName Write-Error
        Mock -CommandName Write-Verbose

    }

    Context 'When the group is read back after the write' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'vg-id'; name = 'TestVG' } }
            Mock -CommandName List-DevOpsVariableGroups -MockWith {
                return @(
                    [PSCustomObject]@{ id = 'other-id'; name = 'Other'; description = 'not this one' }
                    [PSCustomObject]@{ id = 'vg-id'; name = 'TestVG'; description = 'as stored' }
                )
            }
        }

        It 'Should cache the group as the API reads it back, not the write response' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Description 'as stored'

            Assert-MockCalled -CommandName List-DevOpsVariableGroups -Exactly 1 -ParameterFilter {
                $ProjectName -eq 'TestProject' -and $ApiUri -eq 'https://dev.azure.com/TestOrganization'
            }
            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestVG' -and $Value.id -eq 'vg-id' -and $Value.description -eq 'as stored'
            }
        }

        It 'Should fall back to the write response when the read-back does not list the group' {
            Mock -CommandName List-DevOpsVariableGroups -MockWith { return $null }

            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestVG' -and $Value.id -eq 'vg-id'
            }
        }
    }

    Context 'When the variable group exists in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'vg-id'; name = 'TestVG' }
            }
        }

        It 'Should call Set-DevOpsVariableGroup with the group id' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Set-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $VariableGroupId -eq 'vg-id' -and $ProjectName -eq 'TestProject'
            }
        }

        It 'Should update the cache via Add-CacheItem after setting' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestVG' -and $Type -eq 'LiveVariableGroups'
            }
        }

        It 'Should call Export-CacheObject for LiveVariableGroups' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Export-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LiveVariableGroups'
            }
        }

        It 'Should call Refresh-CacheObject for LiveVariableGroups' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly 1 -ParameterFilter {
                $CacheType -eq 'LiveVariableGroups'
            }
        }

    }

    Context 'When variables are configured' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return [PSCustomObject]@{
                    id          = 'vg-id'
                    name        = 'TestVG'
                    description = 'live description'
                    variables   = [PSCustomObject]@{
                        OLD_VAR = [PSCustomObject]@{ value = 'old'; isSecret = $false }
                        OLD_KEY = [PSCustomObject]@{ value = $null; isSecret = $true }
                    }
                }
            }
        }

        It 'Should send the configured set, normalized, in place of the live one' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Variables @{
                APP_ENV = 'production'
                APP_KEY = @{ value = 'p@ssw0rd'; isSecret = $true }
            }

            Assert-MockCalled -CommandName Set-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $Variables.Count -eq 2 -and
                $Variables.APP_ENV.value -eq 'production' -and $Variables.APP_ENV.isSecret -eq $false -and
                $Variables.APP_KEY.value -eq 'p@ssw0rd' -and $Variables.APP_KEY.isSecret -eq $true -and
                -not $Variables.ContainsKey('OLD_VAR')
            }
        }

        It 'Should send a secret declared without a value as a null value' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Variables @{
                OLD_KEY = @{ isSecret = $true }
            }

            Assert-MockCalled -CommandName Set-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $Variables.Count -eq 1 -and $null -eq $Variables.OLD_KEY.value -and $Variables.OLD_KEY.isSecret -eq $true
            }
        }

        It 'Should send an empty set when an empty set is configured' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Variables @{}

            Assert-MockCalled -CommandName Set-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $Variables.Count -eq 0
            }
        }

        It 'Should keep the live description when none is configured' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Variables @{ A = 'x' }

            Assert-MockCalled -CommandName Set-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $Description -eq 'live description'
            }
        }

        It 'Should send the configured description when one is given' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Description 'new description'

            Assert-MockCalled -CommandName Set-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $Description -eq 'new description'
            }
        }

        It 'Should never write a secret value to the verbose stream' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Variables @{
                APP_KEY = @{ value = 'the-configured-secret'; isSecret = $true }
            }

            Should -Invoke -CommandName Write-Verbose -Times 0 -ParameterFilter { $Message -like '*the-configured-secret*' }
        }
    }

    Context 'When variables are not configured' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return [PSCustomObject]@{
                    id        = 'vg-id'
                    name      = 'TestVG'
                    variables = [PSCustomObject]@{
                        OLD_VAR = [PSCustomObject]@{ value = 'old'; isSecret = $false }
                        OLD_KEY = [PSCustomObject]@{ value = $null; isSecret = $true }
                    }
                }
            }
        }

        It 'Should re-send the live variables rather than wiping them' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Description 'changed'

            Assert-MockCalled -CommandName Set-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $Variables.Count -eq 2 -and
                $Variables.OLD_VAR.value -eq 'old' -and $Variables.OLD_VAR.isSecret -eq $false -and
                $null -eq $Variables.OLD_KEY.value -and $Variables.OLD_KEY.isSecret -eq $true
            }
        }

        It 'Should treat a null Variables the same way' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Variables $null

            Assert-MockCalled -CommandName Set-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $Variables.Count -eq 2
            }
        }
    }

    Context 'When the variable group is not found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It 'Should write an error and not call Set-DevOpsVariableGroup' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'MissingVG'

            Assert-MockCalled -CommandName Write-Error -Exactly 1
            Assert-MockCalled -CommandName Set-DevOpsVariableGroup -Exactly 0
        }

        It 'Should not update the cache when group is missing' {
            Set-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'MissingVG'

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 0
        }

    }

}
