$currentFile = $MyInvocation.MyCommand.Path

Describe "Resolve-AzDoPipelineAuthorizationResource" -Tag "Unit", "PipelineAuthorization" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Resolve-AzDoPipelineAuthorizationResource.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when resource type is 'endpoint' and it is found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 11; name = 'MySC' } }
        }

        It "returns the cached id without a live lookup" {
            Mock -CommandName List-DevOpsServiceConnections

            $result = Resolve-AzDoPipelineAuthorizationResource -ProjectName 'TestProject' -ResourceType 'endpoint' -ResourceName 'MySC'

            $result | Should -Be '11'
            Assert-MockCalled -CommandName List-DevOpsServiceConnections -Times 0
        }
    }

    Context "when resource type is 'endpoint' and it is missing from cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName Add-CacheItem
        }

        It "falls back to a live lookup and caches the match" {
            Mock -CommandName List-DevOpsServiceConnections -MockWith { return @(@{ id = 22; name = 'MySC' }, @{ id = 33; name = 'Other' }) }

            $result = Resolve-AzDoPipelineAuthorizationResource -ProjectName 'TestProject' -ResourceType 'endpoint' -ResourceName 'MySC'

            $result | Should -Be '22'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter { $Type -eq 'LiveServiceConnections' } -Times 1
        }

        It "returns `$null when no live resource matches" {
            Mock -CommandName List-DevOpsServiceConnections -MockWith { return @() }

            $result = Resolve-AzDoPipelineAuthorizationResource -ProjectName 'TestProject' -ResourceType 'endpoint' -ResourceName 'MySC'

            $result | Should -BeNullOrEmpty
        }
    }

    Context "when resource type is 'queue'" {
        It "resolves via LiveAgentQueues" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 5; name = 'DefaultQueue' } }

            $result = Resolve-AzDoPipelineAuthorizationResource -ProjectName 'TestProject' -ResourceType 'queue' -ResourceName 'DefaultQueue'

            $result | Should -Be '5'
        }
    }

    Context "when resource type is 'variablegroup'" {
        It "resolves via LiveVariableGroups" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 7; name = 'Prod Secrets' } }

            $result = Resolve-AzDoPipelineAuthorizationResource -ProjectName 'TestProject' -ResourceType 'variablegroup' -ResourceName 'Prod Secrets'

            $result | Should -Be '7'
        }
    }

    Context "when resource type is 'securefile'" {
        It "resolves via LiveSecureFiles" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 9; name = 'cert.pfx' } }

            $result = Resolve-AzDoPipelineAuthorizationResource -ProjectName 'TestProject' -ResourceType 'securefile' -ResourceName 'cert.pfx'

            $result | Should -Be '9'
        }
    }

    Context "when resource type is 'environment'" {
        It "resolves via LivePipelineEnvironments" {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 3; name = 'Production' } }

            $result = Resolve-AzDoPipelineAuthorizationResource -ProjectName 'TestProject' -ResourceType 'environment' -ResourceName 'Production'

            $result | Should -Be '3'
        }
    }

    Context "when resource type is 'repository'" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LiveRepositories') { return @{ id = 'repo-guid'; name = 'MyRepo' } }
                return $null
            }
            Mock -CommandName Resolve-AzDoProject -MockWith { return @{ id = 'project-guid' } }
        }

        It "composes the id as '{projectId}.{repositoryId}'" {
            $result = Resolve-AzDoPipelineAuthorizationResource -ProjectName 'TestProject' -ResourceType 'repository' -ResourceName 'MyRepo'

            $result | Should -Be 'project-guid.repo-guid'
        }

        It "returns `$null when the project cannot be resolved" {
            Mock -CommandName Resolve-AzDoProject -MockWith { return $null }

            $result = Resolve-AzDoPipelineAuthorizationResource -ProjectName 'TestProject' -ResourceType 'repository' -ResourceName 'MyRepo'

            $result | Should -BeNullOrEmpty
        }
    }

    Context "when the resource cannot be found at all" {
        It "returns `$null" {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsAgentQueues -MockWith { return @() }

            $result = Resolve-AzDoPipelineAuthorizationResource -ProjectName 'TestProject' -ResourceType 'queue' -ResourceName 'NoSuchQueue'

            $result | Should -BeNullOrEmpty
        }
    }
}
