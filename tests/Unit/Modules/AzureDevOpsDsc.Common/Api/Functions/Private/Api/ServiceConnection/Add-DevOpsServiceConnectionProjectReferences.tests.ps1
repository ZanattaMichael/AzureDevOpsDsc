$currentFile = $MyInvocation.MyCommand.Path

Describe 'Add-DevOpsServiceConnectionProjectReferences' -Tag "Unit", "ServiceConnection", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Add-DevOpsServiceConnectionProjectReferences.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'sc-id' }
        }

        $script:fabRef = @{ projectReference = @{ id = 'fab-id'; name = 'Fabrikam' }; name = 'shared-conn'; description = '' }
    }

    It 'PATCHes the org-level endpoint for the service connection' {
        Add-DevOpsServiceConnectionProjectReferences -ApiUri 'https://dev.azure.com/myorg/' -ServiceConnectionId 'sc-id' -ProjectReferences @($script:fabRef)

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'PATCH' -and
            $Uri -eq 'https://dev.azure.com/myorg/_apis/serviceendpoint/endpoints/sc-id?api-version=7.1-preview.4'
        }
    }

    It 'Sends a single reference as a JSON array, not an object' {
        Add-DevOpsServiceConnectionProjectReferences -ApiUri 'https://dev.azure.com/myorg' -ServiceConnectionId 'sc-id' -ProjectReferences @($script:fabRef)

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $Body.TrimStart().StartsWith('[') -and
            (@($Body | ConvertFrom-Json) | Measure-Object).Count -eq 1 -and
            (@($Body | ConvertFrom-Json))[0].projectReference.id -eq 'fab-id' -and
            (@($Body | ConvertFrom-Json))[0].name -eq 'shared-conn'
        }
    }

    It 'Sends every reference it is given' {
        $refs = @($script:fabRef, @{ projectReference = @{ id = 'con-id'; name = 'Contoso' }; name = 'TestSC' })
        Add-DevOpsServiceConnectionProjectReferences -ApiUri 'https://dev.azure.com/myorg' -ServiceConnectionId 'sc-id' -ProjectReferences $refs

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            (@($Body | ConvertFrom-Json) | Measure-Object).Count -eq 2
        }
    }

    It 'Throws with the service connection id when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }

        { Add-DevOpsServiceConnectionProjectReferences -ApiUri 'https://dev.azure.com/myorg' -ServiceConnectionId 'sc-id' -ProjectReferences @($script:fabRef) } |
            Should -Throw "*Failed to share service connection 'sc-id'*API error*"
    }
}
