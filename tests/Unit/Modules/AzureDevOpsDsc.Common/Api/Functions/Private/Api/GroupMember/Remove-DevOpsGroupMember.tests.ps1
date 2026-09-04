$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-DevOpsGroupMember' -Tag "Unit", "GroupMember", "API" {
    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-DevOpsGroupMember.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    Context 'When all parameters are valid' {
        It 'Removes a member from the group' {
            $group = [PSCustomObject]@{ descriptor = 'group-descriptor' }
            $member = [PSCustomObject]@{ descriptor = 'member-descriptor' }
            $apiUri = 'https://dev.azure.com/myorg'

            Remove-DevOpsGroupMember -GroupIdentity $group -MemberIdentity $member -ApiUri $apiUri

            # The graph API is preview-only, so the default has to be the pinned preview
            # version rather than whatever Get-AzDevOpsApiVersion -Default returns.
            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -ParameterFilter {
                $ApiUri -eq 'https://dev.azure.com/myorg/_apis/graph/memberships/member-descriptor/group-descriptor?api-version=7.1-preview.1' -and
                $Method -eq 'DELETE'
            } -Times 1
        }
    }

    Context 'When API call fails' {
        It 'Handles the error gracefully' {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API call failed' }
            Mock -CommandName Write-Error -Verifiable

            $group = [PSCustomObject]@{ descriptor = 'group-descriptor' }
            $member = [PSCustomObject]@{ descriptor = 'member-descriptor' }
            $apiUri = 'https://dev.azure.com/myorg'

            { Remove-DevOpsGroupMember -GroupIdentity $group -MemberIdentity $member -ApiUri $apiUri } | Should -Not -Throw
        }
    }

    Context 'When ApiVersion parameter is provided' {
        It 'Uses the specified ApiVersion' {
            $group = [PSCustomObject]@{ descriptor = 'group-descriptor' }
            $member = [PSCustomObject]@{ descriptor = 'member-descriptor' }
            $apiUri = 'https://dev.azure.com/myorg'
            $apiVersion = '6.0'

            Remove-DevOpsGroupMember -GroupIdentity $group -MemberIdentity $member -ApiUri $apiUri -ApiVersion $apiVersion

            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -ParameterFilter {
                $ApiUri -eq "https://dev.azure.com/myorg/_apis/graph/memberships/$($member.descriptor)/$($group.descriptor)?api-version=$apiVersion" -and
                $Method -eq 'DELETE'
            } -Times 1
        }
    }
}
