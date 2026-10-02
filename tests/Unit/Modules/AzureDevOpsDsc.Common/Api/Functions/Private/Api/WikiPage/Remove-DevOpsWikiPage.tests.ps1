$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-DevOpsWikiPage' -Tag "Unit", "WikiPage", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-DevOpsWikiPage.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Format-AzDoWikiPagePath.ps1').FullName

        Mock -CommandName Write-Verbose
    }

    It "calls Invoke-AzDevOpsApiRestMethod with DELETE" {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $true }
        Remove-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter { $Method -eq 'DELETE' }
    }

    It "returns null when the page does not exist" {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'TF401174: The wiki page path does not exist. (404)' }
        $result = Remove-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/Missing'
        $result | Should -BeNullOrEmpty
    }

    It "throws for another API failure" {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'Service unavailable' }
        { Remove-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' } | Should -Throw
    }
}
