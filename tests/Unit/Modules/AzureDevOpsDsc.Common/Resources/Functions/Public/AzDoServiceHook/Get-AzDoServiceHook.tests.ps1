$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoServiceHook' -Tag "Unit", "ServiceHook" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoServiceHook.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        $script:commonParams = @{
            Name             = 'hook1'
            PublisherId      = 'tfs'
            EventType        = 'git.push'
            ConsumerId       = 'webHooks'
            ConsumerActionId = 'httpRequest'
            ConsumerInputs   = @{ url = 'https://ci/hook' }
        }
    }

    Context 'when a matching subscription exists' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsServiceHookSubscription -MockWith {
                return @{ id = 'sub-id'; consumerInputs = @{ url = 'https://ci/hook' }; publisherInputs = @{ projectId = 'p1' } }
            }
        }

        It 'returns Unchanged when inputs match' {
            $result = Get-AzDoServiceHook @commonParams
            $result.status | Should -Be 'Unchanged'
            $result.subscriptionId | Should -Be 'sub-id'
        }

        It 'returns Changed when a consumer input differs' {
            $p = $commonParams.Clone(); $p.ConsumerInputs = @{ url = 'https://ci/other' }
            $result = Get-AzDoServiceHook @p
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'consumerInputs.url'
        }
    }

    Context 'when no matching subscription exists' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsServiceHookSubscription -MockWith { return $null }
        }

        It 'returns status NotFound' {
            $result = Get-AzDoServiceHook @commonParams
            $result.status | Should -Be 'NotFound'
        }
    }
}
