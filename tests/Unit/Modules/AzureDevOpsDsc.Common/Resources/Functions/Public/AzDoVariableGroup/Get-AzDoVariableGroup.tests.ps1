$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoVariableGroup Tests' -Tag "Unit", "VariableGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoVariableGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        # The comparison helpers are the behaviour under test; load them rather than mock them.
        . (Get-FunctionItem 'ConvertTo-AzDoVariableGroupVariables.ps1').FullName
        . (Get-FunctionItem 'Test-AzDoVariableGroupVariableDrift.ps1').FullName

        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Add-CacheItem

        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName List-DevOpsVariableGroups -MockWith { return $null }
    }

    Context 'When the variable group is found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'mock-vg-id'; name = 'TestVG' }
            }
        }

        It 'Should return status Unchanged' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'
            $result.status | Should -Be 'Unchanged'
        }

        It 'Should return Ensure Present' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'
            $result.Ensure | Should -Be 'Present'
        }

        It 'Should populate liveCache with the cached item' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'
            $result.liveCache | Should -Not -BeNullOrEmpty
            $result.liveCache.id | Should -Be 'mock-vg-id'
        }

        It 'Should call Get-CacheItem with the correct composite key' {
            Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'
            Assert-MockCalled -CommandName Get-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestVG' -and $Type -eq 'LiveVariableGroups'
            }
        }

        It 'Should not call the live API' {
            Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'
            Assert-MockCalled -CommandName List-DevOpsVariableGroups -Exactly 0
        }

    }

    Context 'When the variable group is not in cache but exists live' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsVariableGroups -MockWith {
                return @(
                    [PSCustomObject]@{ id = 7; name = 'OtherVG' },
                    [PSCustomObject]@{ id = 8; name = 'TestVG'; description = 'live' }
                )
            }
        }

        It 'Should find it by name and return Unchanged' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'
            $result.status | Should -Be 'Unchanged'
            $result.liveCache.id | Should -Be 8
        }

        It 'Should add it to the cache' {
            Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -ParameterFilter {
                $Key -eq 'TestProject\TestVG' -and $Type -eq 'LiveVariableGroups'
            }
        }
    }

    Context 'When the variable group is not found in cache' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It 'Should return status NotFound' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'MissingVG'
            $result.status | Should -Be 'NotFound'
        }

        It 'Should not populate liveCache' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'MissingVG'
            $result.liveCache | Should -BeNullOrEmpty
        }

        It 'Should return Ensure Absent' {
            $result = Get-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'MissingVG'
            $result.Ensure | Should -Be 'Absent'
        }

    }

    Context 'When the description is managed' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return [PSCustomObject]@{ id = 'vg-42'; name = 'MyVG'; description = 'live description' }
            }
        }

        It 'Should return Unchanged when it matches' {
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Description 'live description'
            $result.status | Should -Be 'Unchanged'
        }

        It 'Should return Changed with Description listed when it differs' {
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Description 'desired description'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Description'
        }

        It 'Should not compare an empty description' {
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Description ''
            $result.status | Should -Be 'Unchanged'
        }

        It 'Should not compare AllowAccess or VariableGroupType' {
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -AllowAccess $true -VariableGroupType 'AzureKeyVault'
            $result.status | Should -Be 'Unchanged'
        }
    }

    Context 'When the variables are managed' {

        BeforeEach {
            # What the API returns: a property bag, a secret with its value withheld.
            Mock -CommandName Get-CacheItem -MockWith {
                return [PSCustomObject]@{
                    id        = 'vg-42'
                    name      = 'MyVG'
                    variables = [PSCustomObject]@{
                        APP_ENV = [PSCustomObject]@{ value = 'production'; isSecret = $false }
                        APP_KEY = [PSCustomObject]@{ value = $null; isSecret = $true }
                    }
                }
            }
        }

        It 'Should return Unchanged when the flat and nested shapes match the live set' {
            $vars = @{ APP_ENV = 'production'; APP_KEY = @{ value = 'whatever-it-cannot-be-read'; isSecret = $true } }
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Variables $vars
            $result.status | Should -Be 'Unchanged'
            $result.propertiesChanged | Should -BeNullOrEmpty
        }

        It 'Should return Unchanged when the secret is declared without a value' {
            $vars = @{ APP_ENV = 'production'; APP_KEY = @{ isSecret = $true } }
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Variables $vars
            $result.status | Should -Be 'Unchanged'
        }

        It 'Should return Changed when a non-secret value differs' {
            $vars = @{ APP_ENV = 'staging'; APP_KEY = @{ isSecret = $true } }
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Variables $vars
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Variables'
        }

        It 'Should return Changed when a configured secret is stored in the clear' {
            $vars = @{ APP_ENV = @{ value = 'production'; isSecret = $true }; APP_KEY = @{ isSecret = $true } }
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Variables $vars
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Variables'
        }

        It 'Should return Changed when a configured non-secret is stored as a secret' {
            $vars = @{ APP_ENV = 'production'; APP_KEY = 'plain' }
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Variables $vars
            $result.status | Should -Be 'Changed'
        }

        It 'Should return Changed when a configured variable is missing live' {
            $vars = @{ APP_ENV = 'production'; APP_KEY = @{ isSecret = $true }; NEW_VAR = 'x' }
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Variables $vars
            $result.status | Should -Be 'Changed'
        }

        It 'Should return Changed when a live variable is not configured' {
            $vars = @{ APP_ENV = 'production' }
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Variables $vars
            $result.status | Should -Be 'Changed'
        }

        It 'Should return Changed with an empty configured set when variables exist live' {
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Variables @{}
            $result.status | Should -Be 'Changed'
        }

        It 'Should not compare variables when none are configured' {
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG'
            $result.status | Should -Be 'Unchanged'

            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Variables $null
            $result.status | Should -Be 'Unchanged'
        }

        It 'Should report both Description and Variables when both differ' {
            $vars = @{ APP_ENV = 'staging' }
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Description 'new' -Variables $vars
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Description'
            $result.propertiesChanged | Should -Contain 'Variables'
        }

        It 'Should never write a configured secret value to the verbose stream' {
            $vars = @{ APP_ENV = 'staging'; APP_KEY = @{ value = 'the-configured-secret'; isSecret = $true }; NEW_KEY = @{ value = 'another-secret'; isSecret = $true } }
            $null = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Variables $vars

            Should -Invoke -CommandName Write-Verbose -Times 0 -ParameterFilter { $Message -like '*the-configured-secret*' -or $Message -like '*another-secret*' }
        }
    }

    Context 'When the live group has no variables' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return [PSCustomObject]@{ id = 'vg-42'; name = 'MyVG' }
            }
        }

        It 'Should return Changed when variables are configured' {
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Variables @{ A = 'x' }
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Variables'
        }

        It 'Should return Unchanged when an empty set is configured' {
            $result = Get-AzDoVariableGroup -ProjectName 'Proj' -VariableGroupName 'MyVG' -Variables @{}
            $result.status | Should -Be 'Unchanged'
        }
    }

}
