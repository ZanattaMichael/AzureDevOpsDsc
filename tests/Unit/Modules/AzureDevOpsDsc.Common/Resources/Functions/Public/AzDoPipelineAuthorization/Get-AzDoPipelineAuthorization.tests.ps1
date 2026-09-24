$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoPipelineAuthorization" -Tag "Unit", "PipelineAuthorization" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoPipelineAuthorization.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the target resource cannot be resolved" {
        It "returns status Error and does not call the pipelinePermissions API" {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return $null }
            Mock -CommandName Get-DevOpsPipelinePermission

            $result = Get-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -ResourceName 'NoSuchVG'

            $result.status | Should -Be 'Error'
            $result.reason | Should -Match 'NoSuchVG'
            Assert-MockCalled -CommandName Get-DevOpsPipelinePermission -Times 0
        }
    }

    Context "when the pipelinePermissions API call fails" {
        It "returns status Error" {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return '4' }
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith { throw 'boom' }

            $result = Get-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -ResourceName 'Prod Secrets'

            $result.status | Should -Be 'Error'
        }
    }

    Context "when a desired pipeline path cannot be resolved" {
        It "returns status Error" {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return '4' }
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith { return @{ allPipelines = @{ authorized = $false }; pipelines = @() } }
            Mock -CommandName Resolve-AzDoPipelineAuthorizationTargets -MockWith { return @(@{ Path = '\Missing\pipeline'; Id = $null }) }

            $result = Get-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -ResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Missing\pipeline')

            $result.status | Should -Be 'Error'
            $result.reason | Should -Match 'Missing\\pipeline'
        }
    }

    Context "additive mode (ExclusiveList = `$false)" {
        BeforeEach {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return '4' }
            Mock -CommandName Resolve-AzDoPipelineAuthorizationTargets -MockWith { return @(@{ Path = '\Platform\deploy-infra'; Id = 101 }) }
        }

        It "is Unchanged when the desired pipeline is already authorized" {
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith {
                return @{ allPipelines = @{ authorized = $false }; pipelines = @(@{ id = 101; authorized = $true }) }
            }

            $result = Get-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -ResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Platform\deploy-infra') -AllPipelines $false -ExclusiveList $false

            $result.status | Should -Be 'Unchanged'
        }

        It "is Unchanged when an extra pipeline is authorized that the config never declared" {
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith {
                return @{ allPipelines = @{ authorized = $false }; pipelines = @(@{ id = 101; authorized = $true }, @{ id = 999; authorized = $true }) }
            }

            $result = Get-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -ResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Platform\deploy-infra') -AllPipelines $false -ExclusiveList $false

            $result.status | Should -Be 'Unchanged'
        }

        It "is Changed when the desired pipeline is not yet authorized" {
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith {
                return @{ allPipelines = @{ authorized = $false }; pipelines = @() }
            }

            $result = Get-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -ResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Platform\deploy-infra') -AllPipelines $false -ExclusiveList $false

            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'AuthorizedPipelines'
        }

        It "is Changed when AllPipelines does not match" {
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith {
                return @{ allPipelines = @{ authorized = $true }; pipelines = @(@{ id = 101; authorized = $true }) }
            }

            $result = Get-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -ResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Platform\deploy-infra') -AllPipelines $false -ExclusiveList $false

            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'AllPipelines'
        }
    }

    Context "exclusive mode (ExclusiveList = `$true)" {
        BeforeEach {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return '4' }
            Mock -CommandName Resolve-AzDoPipelineAuthorizationTargets -MockWith { return @(@{ Path = '\Platform\deploy-infra'; Id = 101 }) }
        }

        It "is Changed when a pipeline is authorized that the config does not declare" {
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith {
                return @{ allPipelines = @{ authorized = $false }; pipelines = @(@{ id = 101; authorized = $true }, @{ id = 999; authorized = $true }) }
            }

            $result = Get-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -ResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Platform\deploy-infra') -AllPipelines $false -ExclusiveList $true

            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'AuthorizedPipelines'
        }

        It "is Unchanged when the authorized set exactly matches the declared list" {
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith {
                return @{ allPipelines = @{ authorized = $false }; pipelines = @(@{ id = 101; authorized = $true }) }
            }

            $result = Get-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -ResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Platform\deploy-infra') -AllPipelines $false -ExclusiveList $true

            $result.status | Should -Be 'Unchanged'
        }
    }
}
