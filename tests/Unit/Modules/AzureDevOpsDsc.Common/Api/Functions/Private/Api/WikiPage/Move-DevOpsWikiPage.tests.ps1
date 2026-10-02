$currentFile = $MyInvocation.MyCommand.Path

Describe 'Move-DevOpsWikiPage' -Tag "Unit", "WikiPage", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Move-DevOpsWikiPage.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Format-AzDoWikiPagePath.ps1').FullName

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ path = '/Runbooks/On-call'; order = 2 } }
    }

    It "calls Invoke-AzDevOpsApiRestMethod with POST" {
        Move-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' -NewOrder 2
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter { $Method -eq 'POST' }
    }

    It "sends the same path as both path and newPath, and the desired order" {
        Move-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' -NewOrder 2
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $bodyObject = $Body | ConvertFrom-Json
            $bodyObject.path -eq '/Runbooks/On-call' -and $bodyObject.newPath -eq '/Runbooks/On-call' -and $bodyObject.newOrder -eq 2
        }
    }

    It "throws a clear error when the API call fails" {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'Service unavailable' }
        { Move-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' -NewOrder 2 } | Should -Throw '*reorder*'
    }
}
