$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoCacheObjects' {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath "Get-AzDoCacheObjects.tests.ps1"
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }
    }

    It 'Returns an array with 34 elements' {
        $result = Get-AzDoCacheObjects
        $result.Length | Should -Be 34
    }

    It 'Contains all legacy and Live* cache types' {
        $expectedElements = @(
            # Legacy / non-prefixed types
            'Project',
            'Team',
            'Group',
            'SecurityDescriptor',
            'SecurityNamespaces',
            # Live cache types
            'LiveACLList',
            'LiveAgentPools',
            'LiveAgentQueues',
            'LiveAreaNodes',
            'LiveArtifactFeeds',
            'LiveAuditStreams',
            'LiveBranchPolicies',
            'LiveCheckConfigurations',
            'LiveDeploymentGroups',
            'LiveEnvironmentApprovals',
            'LiveExtensions',
            'LiveGroupMembers',
            'LiveGroups',
            'LiveIterations',
            'LiveNotificationSubscriptions',
            'LivePipelineEnvironments',
            'LivePipelines',
            'LivePolicyTypes',
            'LiveProcesses',
            'LiveProjects',
            'LiveRepositories',
            'LiveServiceConnections',
            'LiveServicePrinciples',
            'LiveTaskGroups',
            'LiveTeamMembers',
            'LiveTeams',
            'LiveUsers',
            'LiveVariableGroups',
            'LiveWikis'
        )
        $result = Get-AzDoCacheObjects
        $result | Should -Be $expectedElements
    }
}
