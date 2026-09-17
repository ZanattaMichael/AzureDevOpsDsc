<#
    Unit tests for the integration-test selector.

    Deliberately NOT under Resources\, so Invoke-Tests.ps1 does not pick them up as part
    of the live suite - these are pure and hit nothing.

    The integration workflow runs this file before it uses the selector, because the
    failure mode of a broken selector is silent: it picks too few tests and the run goes
    green having exercised nothing.
#>

BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'Supporting\Functions\Get-AffectedIntegrationTest.ps1')

    $script:IntegrationRoot = $PSScriptRoot
    $script:AllTestCount = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Resources') -Filter '*.tests.ps1' -File).Count

    function Invoke-Selector
    {
        param([String[]]$Path)
        Get-AffectedIntegrationTest -ChangedPath $Path -IntegrationTestRoot $script:IntegrationRoot
    }

    function Get-SelectedName
    {
        param($Result)
        @($Result.Path | ForEach-Object { (Split-Path -Path $_ -Leaf) -replace '\.tests\.ps1$', '' } | Sort-Object)
    }
}

Describe 'Get-AffectedIntegrationTest' -Tag 'Unit' {

    Context 'A resource class change' {

        It 'selects only that resource''s test file' {
            $result = Invoke-Selector -Path 'source/Classes/102.AzDoWorkItemQuery.ps1'

            $result.RunAll | Should -BeFalse
            Get-SelectedName $result | Should -Be @('AzDoWorkItemQuery')
        }

        It 'picks up every variant file for the resource' {
            $result = Invoke-Selector -Path 'source/Classes/020.AzDoProject.ps1'

            $result.RunAll | Should -BeFalse
            Get-SelectedName $result | Should -Be @('AzDoProject.Description', 'AzDoProject.NoDescription')
        }

        It 'does not drag in resources that merely share a name prefix' {
            # The trap: a naive StartsWith('AzDoProject') also matches AzDoProjectGroup,
            # AzDoProjectPermission and AzDoProjectServices.
            $result = Invoke-Selector -Path 'source/Classes/020.AzDoProject.ps1'

            Get-SelectedName $result | Should -Not -Contain 'AzDoProjectGroup.Description'
            Get-SelectedName $result | Should -Not -Contain 'AzDoProjectPermission'
            Get-SelectedName $result | Should -Not -Contain 'AzDoProjectServices'
        }

        It 'handles the lettered class file suffix' {
            $result = Invoke-Selector -Path 'source/Classes/003b.ServicePrincipalToken.ps1'

            # A token class is not a resource, so it is shared code.
            $result.RunAll | Should -BeTrue
        }
    }

    Context 'A base class or shared code change' {

        It 'selects the whole suite for the resource base class' {
            $result = Invoke-Selector -Path 'source/Classes/006.AzDevOpsDscResourceBase.ps1'

            $result.RunAll | Should -BeTrue
            $result.Reason | Should -Match 'Shared code'
        }

        It 'selects the whole suite for the private API layer' {
            $result = Invoke-Selector -Path 'source/Modules/AzureDevOpsDsc.Common/Api/Functions/Private/Helper/New-ACLToken.ps1'

            $result.RunAll | Should -BeTrue
        }

        It 'selects the whole suite for an enum' {
            $result = Invoke-Selector -Path 'source/Enum/Ensure.ps1'

            $result.RunAll | Should -BeTrue
        }

        It 'lets one shared path override many resource paths' {
            $result = Invoke-Selector -Path @(
                'source/Classes/102.AzDoWorkItemQuery.ps1'
                'source/Classes/101.AzDoQueryFolder.ps1'
                'source/Enum/Ensure.ps1'
            )

            $result.RunAll | Should -BeTrue
        }
    }

    Context 'A public resource function change' {

        It 'attributes the change to the owning resource' {
            $result = Invoke-Selector -Path 'source/Modules/AzureDevOpsDsc.Common/Resources/Functions/Public/AzDoWorkItemQuery/Set-AzDoWorkItemQuery.ps1'

            $result.RunAll | Should -BeFalse
            Get-SelectedName $result | Should -Be @('AzDoWorkItemQuery')
        }

        It 'yields nothing for a resource with no integration coverage' {
            # AzDoProcessField has no Resources\AzDoProcessField.tests.ps1.
            $result = Invoke-Selector -Path 'source/Modules/AzureDevOpsDsc.Common/Resources/Functions/Public/AzDoProcessField/Get-AzDoProcessField.ps1'

            $result.RunAll | Should -BeFalse
            $result.Path.Count | Should -Be 0
        }
    }

    Context 'A test file change' {

        It 'selects the changed test file itself' {
            $result = Invoke-Selector -Path 'tests/Integration/Resources/AzDoSecureFile.tests.ps1'

            $result.RunAll | Should -BeFalse
            Get-SelectedName $result | Should -Be @('AzDoSecureFile')
        }

        It 'selects the whole suite when the harness changes' {
            $result = Invoke-Selector -Path 'tests/Integration/Supporting/Teardown.ps1'

            $result.RunAll | Should -BeTrue
        }

        It 'selects the whole suite when the integration workflow changes' {
            $result = Invoke-Selector -Path '.github/workflows/integration-tests.yml'

            $result.RunAll | Should -BeTrue
        }
    }

    Context 'Changes with no runtime effect' {

        It 'ignores documentation and examples' {
            $result = Invoke-Selector -Path @(
                'README.md'
                'CHANGELOG.md'
                'docs/ResourceRoadmap.md'
                'source/Examples/Resources/AzDoProject.md'
                'source/Examples/Resources/AzDoProject/1-AddAzDoProject.ps1'
            )

            $result.RunAll | Should -BeFalse
            $result.Path.Count | Should -Be 0
        }

        It 'ignores unit tests and unrelated workflows' {
            $result = Invoke-Selector -Path @(
                'tests/Unit/Modules/AzureDevOpsDsc.Common/Api/Functions/Private/Cache/Refresh-AzDoCache.tests.ps1'
                '.github/workflows/build.yml'
            )

            $result.RunAll | Should -BeFalse
            $result.Path.Count | Should -Be 0
        }

        It 'still selects the resource when docs change alongside it' {
            $result = Invoke-Selector -Path @(
                'README.md'
                'source/Classes/102.AzDoWorkItemQuery.ps1'
            )

            $result.RunAll | Should -BeFalse
            Get-SelectedName $result | Should -Be @('AzDoWorkItemQuery')
        }
    }

    Context 'Degenerate input' {

        It 'accepts an empty change set without selecting anything' {
            $result = Invoke-Selector -Path @()

            $result.RunAll | Should -BeFalse
            $result.Path.Count | Should -Be 0
        }

        It 'ignores blank entries' {
            $result = Invoke-Selector -Path @('', '   ', 'source/Classes/102.AzDoWorkItemQuery.ps1')

            Get-SelectedName $result | Should -Be @('AzDoWorkItemQuery')
        }

        It 'accepts backslash-separated paths' {
            $result = Invoke-Selector -Path 'source\Classes\102.AzDoWorkItemQuery.ps1'

            Get-SelectedName $result | Should -Be @('AzDoWorkItemQuery')
        }

        It 'de-duplicates when several paths map to the same resource' {
            $result = Invoke-Selector -Path @(
                'source/Classes/102.AzDoWorkItemQuery.ps1'
                'source/Modules/AzureDevOpsDsc.Common/Resources/Functions/Public/AzDoWorkItemQuery/Get-AzDoWorkItemQuery.ps1'
                'tests/Integration/Resources/AzDoWorkItemQuery.tests.ps1'
            )

            $result.Path.Count | Should -Be 1
        }
    }

    Context 'Selection never silently narrows' {

        It 'reports RunAll rather than an empty selection when there are no test files' {
            $empty = Join-Path -Path $TestDrive -ChildPath 'NoTests'
            New-Item -Path (Join-Path -Path $empty -ChildPath 'Resources') -ItemType Directory -Force | Out-Null

            $result = Get-AffectedIntegrationTest -ChangedPath 'source/Classes/020.AzDoProject.ps1' -IntegrationTestRoot $empty

            $result.RunAll | Should -BeTrue
        }

        It 'never selects more files than exist' {
            $result = Invoke-Selector -Path 'source/Classes/020.AzDoProject.ps1'

            $result.Path.Count | Should -BeLessOrEqual $script:AllTestCount
        }
    }
}
