$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-GitImportRequest Tests' -Tag "Unit", "GitRepository", "API" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-GitImportRequest.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod

    }

    Context 'When starting an import from a public URL' {

        It 'should POST to the importRequests endpoint with the gitSource url and no serviceEndpointId' {
            $mockApiUri  = "https://dev.azure.com/org"
            $mockProject = [PSCustomObject]@{ name = 'TestProject'; id = '12345' }
            $mockRepo    = [PSCustomObject]@{ name = 'TestRepo'; id = 'repo-id' }
            $mockUrl     = "https://github.com/MyUser/MyRepo.git"

            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                [PSCustomObject]@{ importRequestId = 1; status = 'queued' }
            } -ParameterFilter {
                ($ApiUri -match [regex]::Escape('/TestProject/_apis/git/repositories/repo-id/importRequests')) -and
                ($Method -eq 'POST') -and
                ($Body -match [regex]::Escape($mockUrl)) -and
                ($Body -notmatch 'serviceEndpointId')
            }

            $result = New-GitImportRequest -ApiUri $mockApiUri -Project $mockProject -Repository $mockRepo -SourceUrl $mockUrl -ApiVersion '7.1'

            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 1
            $result.importRequestId | Should -Be 1
        }
    }

    Context 'When starting an import from a private URL with a service connection' {

        It 'should include serviceEndpointId in the request body' {
            $mockApiUri  = "https://dev.azure.com/org"
            $mockProject = [PSCustomObject]@{ name = 'TestProject'; id = '12345' }
            $mockRepo    = [PSCustomObject]@{ name = 'TestRepo'; id = 'repo-id' }
            $mockUrl     = "https://github.com/MyOrg/PrivateRepo.git"

            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                [PSCustomObject]@{ importRequestId = 2; status = 'queued' }
            } -ParameterFilter {
                $Body -match [regex]::Escape('sc-id')
            }

            $result = New-GitImportRequest -ApiUri $mockApiUri -Project $mockProject -Repository $mockRepo -SourceUrl $mockUrl -ServiceEndpointId 'sc-id' -ApiVersion '7.1'

            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 1
            $result.importRequestId | Should -Be 2
        }
    }

    Context 'When failing to create an import request' {

        It 'should write an error message and not throw' {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw "Boom" }
            Mock -CommandName Write-Error -Verifiable

            { New-GitImportRequest -ApiUri "https://dev.azure.com/org" -Project ([PSCustomObject]@{ name = 'TestProject' }) -Repository ([PSCustomObject]@{ id = 'repo-id' }) -SourceUrl 'https://github.com/MyUser/MyRepo.git' -ApiVersion '7.1' } | Should -Not -Throw

            Assert-VerifiableMock
        }
    }
}
