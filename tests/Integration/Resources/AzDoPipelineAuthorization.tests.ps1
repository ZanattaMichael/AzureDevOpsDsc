Describe "AzDoPipelineAuthorization Integration Tests" -Tag "Integration", "PipelineAuthorization" {

    BeforeAll {

        $PROJECTNAME = 'TEST_PIPELINEAUTH'
        $REPONAME    = 'TESTREPOSITORY_PIPELINEAUTH'
        $PIPELINE    = 'TEST_PIPELINEAUTH_DEF'
        $VGNAME      = 'TEST_PIPELINEAUTH_VG'

        # Reads the live pipelinePermissions state directly, bypassing the module's cache -
        # mirrors the pattern used by Get-DevOpsPipelinePermission but through a plain
        # Invoke-RestMethod call, per CLAUDE.md's integration-test auth pattern.
        function Get-TestPipelinePermission {
            param(
                [Parameter(Mandatory)][string]$ProjectName,
                [Parameter(Mandatory)][string]$ResourceType,
                [Parameter(Mandatory)][string]$ResourceId
            )

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            return Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                'https://dev.azure.com/{0}/{1}/_apis/pipelines/pipelinePermissions/{2}/{3}?api-version=7.1-preview.1' -f
                    $org, $ProjectName, $ResourceType, $ResourceId)
        }

        function Resolve-TestVariableGroupId {
            param([Parameter(Mandatory)][string]$ProjectName, [Parameter(Mandatory)][string]$Name)

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            $groups = (Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                'https://dev.azure.com/{0}/{1}/_apis/distributedtask/variablegroups?api-version=7.1-preview.2' -f $org, $ProjectName)).value

            $match = $groups | Where-Object { $_.name -eq $Name } | Select-Object -First 1
            if (-not $match) { throw "[Resolve-TestVariableGroupId] Variable group '$Name' not found in '$ProjectName'." }
            return $match.id.ToString()
        }

        function Resolve-TestPipelineId {
            param([Parameter(Mandatory)][string]$ProjectName, [Parameter(Mandatory)][string]$Name)

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            $pipelines = (Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                'https://dev.azure.com/{0}/{1}/_apis/pipelines?api-version=7.1' -f $org, $ProjectName)).value

            $match = $pipelines | Where-Object { $_.name -eq $Name } | Select-Object -First 1
            if (-not $match) { throw "[Resolve-TestPipelineId] Pipeline '$Name' not found in '$ProjectName'." }
            return $match.id
        }

        New-TestProject       -ProjectName $PROJECTNAME
        New-TestGitRepository -ProjectName $PROJECTNAME -RepositoryName $REPONAME

        # Create a real pipeline and a real variable group to authorize against each other.
        $pipelineParameters = @{
            Name       = 'AzDoPipeline'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProjectName    = $PROJECTNAME
                PipelineName   = $PIPELINE
                RepositoryName = $REPONAME
                YamlPath       = 'azure-pipelines.yml'
                FolderPath     = '\'
                DefaultBranch  = 'main'
            }
        }
        Invoke-DscResource @pipelineParameters

        $vgParameters = @{
            Name       = 'AzDoVariableGroup'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProjectName       = $PROJECTNAME
                VariableGroupName = $VGNAME
                Description       = 'Pipeline authorization integration test target'
                Variables         = @{
                    MyVar1 = @{ value = 'Value1'; isSecret = $false }
                }
            }
        }
        Invoke-DscResource @vgParameters

        $VGID = Resolve-TestVariableGroupId -ProjectName $PROJECTNAME -Name $VGNAME

        $parameters = @{
            Name       = 'AzDoPipelineAuthorization'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName         = $PROJECTNAME
                ResourceType        = 'variablegroup'
                ResourceName        = $VGNAME
                AuthorizedPipelines = @($PIPELINE)
                AllPipelines        = $false
                ExclusiveList       = $false
            }
        }
    }

    Context "Testing if pipeline authorization exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing pipeline authorization" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (pipeline is not yet authorized)" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Authorizing a pipeline (open access off)" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when authorizing the pipeline" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after authorizing the pipeline" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should show the pipeline as authorized and open access as disabled in Azure DevOps" {
            $pipelineId = Resolve-TestPipelineId -ProjectName $PROJECTNAME -Name $PIPELINE
            $live       = Get-TestPipelinePermission -ProjectName $PROJECTNAME -ResourceType 'variablegroup' -ResourceId $VGID

            $live.allPipelines.authorized | Should -BeFalse
            @($live.pipelines | Where-Object { $_.id -eq $pipelineId -and $_.authorized -eq $true }).Count | Should -Be 1
        }
    }

    Context "Removing pipeline authorization" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                ResourceType        = 'variablegroup'
                ResourceName        = $VGNAME
                AuthorizedPipelines = @($PIPELINE)
                Ensure              = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing pipeline authorization" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        # Note: unlike resources with a genuine create/delete lifecycle, pipeline authorization is a
        # setting on an always-existing resource (see New-AzDoPipelineAuthorization's description).
        # Get-AzDoPipelineAuthorization never reports 'NotFound', so per
        # AzDevOpsDscResourceBase.GetDscRequiredAction()'s Ensure=Absent branch, Test() always maps
        # to 'Remove' rather than converging to True. AzDoPipelineSettings.tests.ps1 (the sibling
        # settings-only resource) follows the same precedent of not asserting Test() after removal -
        # only that Set() applies and the live state changed, verified below.

        It "Should show the pipeline as no longer authorized in Azure DevOps" {
            $pipelineId = Resolve-TestPipelineId -ProjectName $PROJECTNAME -Name $PIPELINE
            $live       = Get-TestPipelinePermission -ProjectName $PROJECTNAME -ResourceType 'variablegroup' -ResourceId $VGID

            @($live.pipelines | Where-Object { $_.id -eq $pipelineId -and $_.authorized -eq $true }).Count | Should -Be 0
        }
    }
}
