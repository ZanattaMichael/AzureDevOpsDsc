$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsTeamMember' -Tag "Unit", "Team", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsTeamMember.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 1; name = 'mock-item' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PUT method' {
        New-DevOpsTeamMember -ApiUri 'https://dev.azure.com/myorg' -GroupDescriptor 'group-desc' -MemberDescriptor 'member-desc'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'PUT'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = New-DevOpsTeamMember -ApiUri 'https://dev.azure.com/myorg' -GroupDescriptor 'group-desc' -MemberDescriptor 'member-desc'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { New-DevOpsTeamMember -ApiUri 'https://dev.azure.com/myorg' -GroupDescriptor 'group-desc' -MemberDescriptor 'member-desc' } | Should -Throw
    }
}
