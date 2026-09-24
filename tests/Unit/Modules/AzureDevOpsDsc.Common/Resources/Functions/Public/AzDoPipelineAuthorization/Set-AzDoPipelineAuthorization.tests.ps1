$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoPipelineAuthorization" -Tag "Unit", "PipelineAuthorization" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoPipelineAuthorization.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Write-Error
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
    }

    Context "when the target resource cannot be resolved" {
        It "writes an error and never calls Set-DevOpsPipelinePermission" {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return $null }
            Mock -CommandName Set-DevOpsPipelinePermission

            Set-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'NoSuchVG'

            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsPipelinePermission -Times 0
        }
    }

    Context "when a desired pipeline path cannot be resolved" {
        It "writes an error and never calls Set-DevOpsPipelinePermission" {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return '4' }
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith { return @{ pipelines = @() } }
            Mock -CommandName Resolve-AzDoPipelineAuthorizationTargets -MockWith { return @(@{ Path = '\Missing\pipeline'; Id = $null }) }
            Mock -CommandName Set-DevOpsPipelinePermission

            Set-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Missing\pipeline')

            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsPipelinePermission -Times 0
        }
    }

    Context "additive mode (ExclusiveList = `$false)" {
        BeforeEach {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return '4' }
            Mock -CommandName Resolve-AzDoPipelineAuthorizationTargets -MockWith { return @(@{ Path = '\Platform\deploy-infra'; Id = 101 }) }
            Mock -CommandName Set-DevOpsPipelinePermission -MockWith { return @{ resource = @{ id = '4' } } }
        }

        It "authorizes only the pipelines that are not already authorized, and leaves other authorized pipelines alone" {
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith {
                return @{ pipelines = @(@{ id = 999; authorized = $true }) }
            }

            Set-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Platform\deploy-infra') -AllPipelines $false -ExclusiveList $false

            Assert-MockCalled -CommandName Set-DevOpsPipelinePermission -ParameterFilter {
                $PipelineAuthorizations.Count -eq 1 -and $PipelineAuthorizations[0].id -eq 101 -and $PipelineAuthorizations[0].authorized -eq $true
            } -Times 1
        }

        It "sends no PipelineAuthorizations when the desired pipeline is already authorized" {
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith {
                return @{ pipelines = @(@{ id = 101; authorized = $true }) }
            }

            Set-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Platform\deploy-infra') -AllPipelines $false -ExclusiveList $false

            Assert-MockCalled -CommandName Set-DevOpsPipelinePermission -ParameterFilter {
                -not $PipelineAuthorizations
            } -Times 1
        }

        It "always sends AllPipelinesAuthorized" {
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith { return @{ pipelines = @() } }

            Set-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Platform\deploy-infra') -AllPipelines $true -ExclusiveList $false

            Assert-MockCalled -CommandName Set-DevOpsPipelinePermission -ParameterFilter {
                $AllPipelinesAuthorized -eq $true
            } -Times 1
        }

        It "caches the returned value on success" {
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith { return @{ pipelines = @() } }

            Set-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Platform\deploy-infra') -AllPipelines $false -ExclusiveList $false

            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter {
                $Type -eq 'LivePipelineAuthorizations' -and $Key -eq 'TestProject\variablegroup\Prod Secrets'
            } -Times 1
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "exclusive mode (ExclusiveList = `$true)" {
        BeforeEach {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return '4' }
            Mock -CommandName Resolve-AzDoPipelineAuthorizationTargets -MockWith { return @(@{ Path = '\Platform\deploy-infra'; Id = 101 }) }
            Mock -CommandName Set-DevOpsPipelinePermission -MockWith { return @{ resource = @{ id = '4' } } }
        }

        It "revokes a pipeline authorized in the portal but absent from AuthorizedPipelines" {
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith {
                return @{ pipelines = @(@{ id = 101; authorized = $true }, @{ id = 999; authorized = $true }) }
            }

            Set-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Platform\deploy-infra') -AllPipelines $false -ExclusiveList $true

            Assert-MockCalled -CommandName Set-DevOpsPipelinePermission -ParameterFilter {
                $PipelineAuthorizations.Count -eq 1 -and
                $PipelineAuthorizations[0].id -eq 999 -and
                $PipelineAuthorizations[0].authorized -eq $false
            } -Times 1
        }
    }

    Context "when Set-DevOpsPipelinePermission returns `$null" {
        It "writes an error and does not cache anything" {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return '4' }
            Mock -CommandName Get-DevOpsPipelinePermission -MockWith { return @{ pipelines = @() } }
            Mock -CommandName Resolve-AzDoPipelineAuthorizationTargets -MockWith { return @() }
            Mock -CommandName Set-DevOpsPipelinePermission -MockWith { return $null }

            Set-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'Prod Secrets' -AllPipelines $false

            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Add-CacheItem -Times 0
        }
    }
}
