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

        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsVariableGroup   -MockWith { return @{ id = 'new-vg-id'; name = 'TestVG' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Resolve-AzDoSharedProjectReferences
        Mock -CommandName Write-Error

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

    }

    Context 'When VariableGroupType is specified' {

        It 'Should forward the custom type to New-DevOpsVariableGroup' {
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -VariableGroupType 'AzureKeyVault'

            Assert-MockCalled -CommandName New-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $Type -eq 'AzureKeyVault'
            }
        }

    }

    Context 'When SharedWithProjects is not specified' {

        It 'Should not resolve project references' {
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Resolve-AzDoSharedProjectReferences -Exactly 0
        }

    }

    Context 'When SharedWithProjects is specified' {

        BeforeEach {
            Mock -CommandName Resolve-AzDoSharedProjectReferences -MockWith {
                @(
                    @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestVG' },
                    @{ projectReference = @{ id = 'p2'; name = 'Fabrikam' }; name = 'shared-settings' }
                )
            }
        }

        It 'Should resolve project references with the owning project and shares' {
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -SharedWithProjects @('Fabrikam') -SharedNameOverrides @{ Fabrikam = 'shared-settings' }

            Assert-MockCalled -CommandName Resolve-AzDoSharedProjectReferences -Exactly 1 -ParameterFilter {
                $ProjectName -eq 'TestProject' -and
                $DefaultName -eq 'TestVG' -and
                $SharedWithProjects -contains 'Fabrikam'
            }
        }

        It 'Should pass the resolved references to New-DevOpsVariableGroup' {
            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -SharedWithProjects @('Fabrikam')

            Assert-MockCalled -CommandName New-DevOpsVariableGroup -Exactly 1 -ParameterFilter {
                $ProjectReferences.Count -eq 2
            }
        }

        It 'Should write an error and not create the group when the resolve throws' {
            Mock -CommandName Resolve-AzDoSharedProjectReferences -MockWith { throw "Project 'Fabrikam' was not found; cannot share with it." }

            New-AzDoVariableGroup -ProjectName 'TestProject' -VariableGroupName 'TestVG' -SharedWithProjects @('Fabrikam')

            Assert-MockCalled -CommandName Write-Error -Exactly 1
            Assert-MockCalled -CommandName New-DevOpsVariableGroup -Exactly 0
        }

    }

}
