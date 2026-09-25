$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsOrganizationPolicyMap' -Tag "Unit", "OrganizationSettings", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsOrganizationPolicyMap.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    It 'maps every managed property to a policy name' {
        $map = Get-DevOpsOrganizationPolicyMap
        $map.PropertyName | Should -Contain 'EnableIPConditionalAccessPolicyValidation'
        $map.PropertyName | Should -Contain 'LogAuditEvents'
        $map.PropertyName | Should -Contain 'AllowTeamAdminsToInviteUsers'
        $map.PropertyName | Should -Contain 'EnableRequestAccess'
        $map.PropertyName | Should -Contain 'EnableArtifactsFeedUpstreamProtection'
    }

    It 'gives every entry a non-empty policy name' {
        $map = Get-DevOpsOrganizationPolicyMap
        foreach ($entry in $map)
        {
            $entry.PolicyName | Should -Not -BeNullOrEmpty
        }
    }

    It 'gives every entry a default of true or false' {
        $map = Get-DevOpsOrganizationPolicyMap
        foreach ($entry in $map)
        {
            $entry.DefaultValue | Should -BeIn @('true', 'false') -Because "policy '$($entry.PolicyName)' needs a default for the per-policy read"
        }
    }

    It 'has no duplicate property names' {
        $map = Get-DevOpsOrganizationPolicyMap
        ($map.PropertyName | Select-Object -Unique).Count | Should -Be $map.Count
    }
}
