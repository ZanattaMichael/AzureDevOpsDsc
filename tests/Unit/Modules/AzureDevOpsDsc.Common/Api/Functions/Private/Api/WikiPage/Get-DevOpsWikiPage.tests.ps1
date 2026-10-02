$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsWikiPage' -Tag "Unit", "WikiPage", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsWikiPage.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Format-AzDoWikiPagePath.ps1').FullName

        Mock -CommandName Write-Verbose
    }

    Context "when the page exists" {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return [PSCustomObject]@{
                    Value   = [PSCustomObject]@{ path = '/Runbooks/On-call'; content = '# On-call'; order = 1 }
                    Headers = @{ ETag = @('"3"') }
                }
            }
        }

        It "returns the page and its ETag" {
            $result = Get-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' -IncludeContent
            $result.Page.path | Should -Be '/Runbooks/On-call'
            $result.ETag | Should -Be '"3"'
        }

        It "calls Invoke-AzDevOpsApiRestMethod with GET and IncludeResponseHeaders" {
            Get-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
                $Method -eq 'GET' -and $IncludeResponseHeaders
            }
        }
    }

    Context "when the response carries no ETag header" {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return [PSCustomObject]@{
                    Value   = [PSCustomObject]@{ path = '/Runbooks/On-call'; content = '# On-call'; order = 1 }
                    Headers = @{}
                }
            }
        }

        It "returns a null ETag" {
            $result = Get-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call'
            $result.ETag | Should -BeNullOrEmpty
        }
    }

    Context "when the page does not exist" {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'TF401174: The wiki page path does not exist. (404)' }
        }

        It "returns null" {
            $result = Get-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/Missing'
            $result | Should -BeNullOrEmpty
        }
    }

    Context "when the API call fails for another reason" {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'Service unavailable' }
        }

        It "throws" {
            { Get-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' } | Should -Throw
        }
    }
}
