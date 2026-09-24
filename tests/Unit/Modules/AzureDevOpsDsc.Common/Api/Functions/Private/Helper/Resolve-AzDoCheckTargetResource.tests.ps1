$currentFile = $MyInvocation.MyCommand.Path

Describe "Resolve-AzDoCheckTargetResource" -Tag "Unit", "CheckConfiguration" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Resolve-AzDoCheckTargetResource.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        # Get-CacheItem's [OutputType([CacheItem])] and its -Type ValidateScript both need these
        # loaded before Pester can build a mock proxy for it - see New-ACLToken.tests.ps1 for the
        # same pattern.
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Add-CacheItem
    }

    Context "environment" {

        It "resolves from cache without a live lookup" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 1; name = 'TestEnv' } }
            Mock -CommandName List-DevOpsPipelineEnvironments -MockWith { return $null }

            $result = Resolve-AzDoCheckTargetResource -ProjectName 'TestProject' -ResourceType 'environment' -TargetResourceName 'TestEnv'

            $result.Id | Should -Be '1'
            Assert-MockCalled -CommandName List-DevOpsPipelineEnvironments -Times 0
        }

        It "falls back to a live lookup on a cache miss and caches the result" {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsPipelineEnvironments -MockWith { return @(@{ id = 7; name = 'TestEnv' }) }

            $result = Resolve-AzDoCheckTargetResource -ProjectName 'TestProject' -ResourceType 'environment' -TargetResourceName 'TestEnv'

            $result.Id | Should -Be '7'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter { $Type -eq 'LivePipelineEnvironments' } -Times 1
        }

        It "returns a null Id when the environment cannot be found" {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsPipelineEnvironments -MockWith { return @() }

            $result = Resolve-AzDoCheckTargetResource -ProjectName 'TestProject' -ResourceType 'environment' -TargetResourceName 'Missing'

            $result.Id | Should -BeNullOrEmpty
        }
    }

    Context "repository" {

        It "resolves from cache" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'repo-1'; name = 'TestRepo' } }

            $result = Resolve-AzDoCheckTargetResource -ProjectName 'TestProject' -ResourceType 'repository' -TargetResourceName 'TestRepo'

            $result.Id | Should -Be 'repo-1'
        }

        It "returns a null Id on a cache miss (no live fallback)" {
            Mock -CommandName Get-CacheItem -MockWith { return $null }

            $result = Resolve-AzDoCheckTargetResource -ProjectName 'TestProject' -ResourceType 'repository' -TargetResourceName 'Missing'

            $result.Id | Should -BeNullOrEmpty
        }
    }

    Context "endpoint" {

        It "resolves from cache" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'sc-1'; name = 'TestConnection' } }

            $result = Resolve-AzDoCheckTargetResource -ProjectName 'TestProject' -ResourceType 'endpoint' -TargetResourceName 'TestConnection'

            $result.Id | Should -Be 'sc-1'
        }
    }

    Context "queue" {

        It "resolves the PROJECT queue id from cache, not an org pool id" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 42; name = 'ProdQueue'; pool = @{ id = 999 } } }
            Mock -CommandName List-DevOpsAgentQueues -MockWith { return $null }

            $result = Resolve-AzDoCheckTargetResource -ProjectName 'TestProject' -ResourceType 'queue' -TargetResourceName 'ProdQueue'

            $result.Id | Should -Be '42'
            Assert-MockCalled -CommandName List-DevOpsAgentQueues -Times 0
        }

        It "falls back to a live lookup on a cache miss and caches the result under LiveAgentQueues" {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsAgentQueues -MockWith { return @(@{ id = 43; name = 'ProdQueue' }) }

            $result = Resolve-AzDoCheckTargetResource -ProjectName 'TestProject' -ResourceType 'queue' -TargetResourceName 'ProdQueue'

            $result.Id | Should -Be '43'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter {
                $Type -eq 'LiveAgentQueues' -and $Key -eq 'TestProject\ProdQueue'
            } -Times 1
        }
    }

    Context "variablegroup" {

        It "resolves from cache" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 10; name = 'TestVG' } }
            Mock -CommandName List-DevOpsVariableGroups -MockWith { return $null }

            $result = Resolve-AzDoCheckTargetResource -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'TestVG'

            $result.Id | Should -Be '10'
        }

        It "falls back to a live lookup on a cache miss" {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsVariableGroups -MockWith { return @(@{ id = 11; name = 'TestVG' }) }

            $result = Resolve-AzDoCheckTargetResource -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'TestVG'

            $result.Id | Should -Be '11'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter { $Type -eq 'LiveVariableGroups' } -Times 1
        }
    }

    Context "securefile" {

        It "resolves from cache" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'sf-1'; name = 'signing.pfx' } }
            Mock -CommandName List-DevOpsSecureFiles -MockWith { return $null }

            $result = Resolve-AzDoCheckTargetResource -ProjectName 'TestProject' -ResourceType 'securefile' -TargetResourceName 'signing.pfx'

            $result.Id | Should -Be 'sf-1'
        }

        It "falls back to a live lookup on a cache miss" {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsSecureFiles -MockWith { return @(@{ id = 'sf-2'; name = 'signing.pfx' }) }

            $result = Resolve-AzDoCheckTargetResource -ProjectName 'TestProject' -ResourceType 'securefile' -TargetResourceName 'signing.pfx'

            $result.Id | Should -Be 'sf-2'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter { $Type -eq 'LiveSecureFiles' } -Times 1
        }
    }

    Context "an unrecognised ResourceType" {

        It "falls back to treating the name as the id" {
            $result = Resolve-AzDoCheckTargetResource -ProjectName 'TestProject' -ResourceType 'somethingelse' -TargetResourceName 'literal-id'
            $result.Id | Should -Be 'literal-id'
        }
    }
}
