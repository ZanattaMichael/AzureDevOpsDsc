$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoPipelineAuthorization" -Tag "Unit", "PipelineAuthorization" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoPipelineAuthorization.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Write-Error
        Mock -CommandName Write-Warning
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
    }

    Context "when the target resource cannot be resolved" {
        It "writes an error and never calls Set-DevOpsPipelinePermission" {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return $null }
            Mock -CommandName Set-DevOpsPipelinePermission

            Remove-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'NoSuchVG'

            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsPipelinePermission -Times 0
        }
    }

    Context "when AuthorizedPipelines was declared" {
        BeforeEach {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return '4' }
            Mock -CommandName Set-DevOpsPipelinePermission -MockWith { return @{ resource = @{ id = '4' } } }
        }

        It "revokes only the declared pipelines and always resets AllPipelines to `$false" {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationTargets -MockWith { return @(@{ Path = '\Platform\deploy-infra'; Id = 101 }) }

            Remove-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Platform\deploy-infra') -AllPipelines $true -ExclusiveList $true

            Assert-MockCalled -CommandName Set-DevOpsPipelinePermission -ParameterFilter {
                $AllPipelinesAuthorized -eq $false -and
                $PipelineAuthorizations.Count -eq 1 -and
                $PipelineAuthorizations[0].id -eq 101 -and
                $PipelineAuthorizations[0].authorized -eq $false
            } -Times 1
        }

        It "skips a path it cannot resolve and warns, rather than failing the whole revoke" {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationTargets -MockWith { return @(@{ Path = '\Missing\pipeline'; Id = $null }) }

            Remove-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'Prod Secrets' `
                -AuthorizedPipelines @('\Missing\pipeline')

            Assert-MockCalled -CommandName Write-Warning -Times 1
            Assert-MockCalled -CommandName Set-DevOpsPipelinePermission -ParameterFilter {
                -not $PipelineAuthorizations
            } -Times 1
        }
    }

    Context "when AuthorizedPipelines was not declared" {
        It "only resets AllPipelines to `$false" {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return '4' }
            Mock -CommandName Set-DevOpsPipelinePermission -MockWith { return @{ resource = @{ id = '4' } } }

            Remove-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'environment' -TargetResourceName 'Production'

            Assert-MockCalled -CommandName Set-DevOpsPipelinePermission -ParameterFilter {
                $AllPipelinesAuthorized -eq $false -and -not $PipelineAuthorizations
            } -Times 1
        }
    }

    Context "on success" {
        It "removes the cache entry and exports the cache" {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return '4' }
            Mock -CommandName Set-DevOpsPipelinePermission -MockWith { return @{ resource = @{ id = '4' } } }

            Remove-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'environment' -TargetResourceName 'Production'

            Assert-MockCalled -CommandName Remove-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\environment\Production' -and $Type -eq 'LivePipelineAuthorizations'
            } -Times 1
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when Set-DevOpsPipelinePermission returns `$null" {
        It "writes an error and does not touch the cache" {
            Mock -CommandName Resolve-AzDoPipelineAuthorizationResource -MockWith { return '4' }
            Mock -CommandName Set-DevOpsPipelinePermission -MockWith { return $null }

            Remove-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'environment' -TargetResourceName 'Production'

            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-CacheItem -Times 0
        }
    }
}
