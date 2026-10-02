$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsWikiPage' -Tag "Unit", "WikiPage", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsWikiPage.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Format-AzDoWikiPagePath.ps1').FullName

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ path = '/Runbooks/On-call' } }
    }

    It "calls Invoke-AzDevOpsApiRestMethod with PUT" {
        Set-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter { $Method -eq 'PUT' }
    }

    It "does not send If-Match when no ETag is supplied" {
        Set-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            -not $AdditionalHeaders.ContainsKey('If-Match')
        }
    }

    It "sends the supplied ETag as If-Match" {
        Set-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' -ETag '"1"'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $AdditionalHeaders['If-Match'] -eq '"1"'
        }
    }

    It "raises a clear error on a stale ETag (412)" {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'Conflict (412)' }
        { Set-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' -ETag '"1"' } | Should -Throw '*changed by someone else*'
    }

    It "throws for another API failure" {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'Service unavailable' }
        { Set-DevOpsWikiPage -Organization 'myorg' -ProjectName 'MyProject' -WikiIdentifier 'MyProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' } | Should -Throw
    }
}
