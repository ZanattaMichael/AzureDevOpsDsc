$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoOrganizationPermission' -Tag "Unit", "OrganizationPermission" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoOrganizationPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Set-AzDoOrganizationPermission
    }

    It 'applies the permissions through Set-AzDoOrganizationPermission with the same arguments' {
        $lookup = @{ aclToken = 'NAMESPACE:' }
        New-AzDoOrganizationPermission -GroupName 'G' -LookupResult $lookup
        Assert-MockCalled -CommandName Set-AzDoOrganizationPermission -Times 1 -ParameterFilter {
            $GroupName -eq 'G' -and $LookupResult.aclToken -eq 'NAMESPACE:'
        }
    }
}
