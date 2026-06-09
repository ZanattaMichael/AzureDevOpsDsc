$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoOrganizationSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoOrganizationSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Write-Warning
    }

    Context "when settings can be retrieved and match" {
        BeforeEach {
            Mock -CommandName Get-DevOpsOrganizationSettings -MockWith {
                return @{
                    'Microsoft.VisualStudio.Services.EnablePublicProjects' = 'false'
                }
            }
        }

        It "returns status Unchanged when AllowPublicProjects matches" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -AllowPublicProjects $false
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when AllowPublicProjects differs" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -AllowPublicProjects $true
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'AllowPublicProjects'
        }

        It "populates liveCache" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization'
            $result.liveCache | Should -Not -BeNullOrEmpty
        }
    }

    Context "when settings API call fails" {
        BeforeEach {
            Mock -CommandName Get-DevOpsOrganizationSettings -MockWith {
                throw "API unavailable"
            }
        }

        It "returns status Error" {
            $result = Get-AzDoOrganizationSettings -OrganizationName 'TestOrganization'
            $result.status | Should -Be 'Error'
        }
    }
}
