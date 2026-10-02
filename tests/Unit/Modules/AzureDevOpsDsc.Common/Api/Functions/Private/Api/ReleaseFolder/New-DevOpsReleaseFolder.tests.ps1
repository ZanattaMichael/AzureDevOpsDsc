$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsReleaseFolder' -Tag "Unit", "ReleaseFolder", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsReleaseFolder.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
        . (Get-FunctionItem 'Format-AzDoPipelineFolderPath.ps1')

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ path = '\Platform' } }
    }

    It 'creates the folder with a POST to the folders collection, not a PUT with ?path=' {
        New-DevOpsReleaseFolder -Organization 'myorg' -ProjectName 'My Project' -Path '\Platform'

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $Method -eq 'POST' -and
            $Uri -eq 'https://vsrm.dev.azure.com/myorg/My%20Project/_apis/release/folders?api-version=7.1'
        }
    }

    It 'carries the normalized path and the description in the body' {
        New-DevOpsReleaseFolder -Organization 'myorg' -ProjectName 'MyProject' -Path 'Platform/Release/' -Description 'Release pipelines'

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $body.path -eq '\Platform\Release' -and $body.description -eq 'Release pipelines'
        }
    }

    It 'leaves the description out when it is not supplied' {
        New-DevOpsReleaseFolder -Organization 'myorg' -ProjectName 'MyProject' -Path '\Platform'

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $null -eq ($Body | ConvertFrom-Json).PSObject.Properties['description']
        }
    }

    It 'names classic Release Management being disabled when the service says so' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'Creation of classic release pipelines has been disabled' }

        { New-DevOpsReleaseFolder -Organization 'myorg' -ProjectName 'MyProject' -Path '\Platform' } |
            Should -Throw '*classic Release Management*appears to be disabled*'
    }

    It 'throws with the folder path for any other failure' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }

        { New-DevOpsReleaseFolder -Organization 'myorg' -ProjectName 'MyProject' -Path '\Platform' } |
            Should -Throw "*'\Platform'*API error*"
    }
}
