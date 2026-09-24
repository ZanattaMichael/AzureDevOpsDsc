$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoPipelineAuthorization" -Tag "Unit", "PipelineAuthorization" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoPipelineAuthorization.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Set-AzDoPipelineAuthorization
    }

    It "delegates directly to Set-AzDoPipelineAuthorization" {
        New-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'variablegroup' -TargetResourceName 'Prod Secrets' `
            -AuthorizedPipelines @('\Platform\deploy-infra') -AllPipelines $true -ExclusiveList $true

        Assert-MockCalled -CommandName Set-AzDoPipelineAuthorization -ParameterFilter {
            $ProjectName -eq 'TestProject' -and
            $ResourceType -eq 'variablegroup' -and
            $TargetResourceName -eq 'Prod Secrets' -and
            $AuthorizedPipelines -contains '\Platform\deploy-infra' -and
            $AllPipelines -eq $true -and
            $ExclusiveList -eq $true
        } -Times 1
    }

    It "creates no resource-level side effects of its own" {
        # New has no create/delete semantics of its own for this resource - it is a pure delegation,
        # so nothing beyond calling Set-AzDoPipelineAuthorization should ever be asserted here.
        New-AzDoPipelineAuthorization -ProjectName 'TestProject' -ResourceType 'environment' -TargetResourceName 'Production'

        Assert-MockCalled -CommandName Set-AzDoPipelineAuthorization -Times 1
    }
}
