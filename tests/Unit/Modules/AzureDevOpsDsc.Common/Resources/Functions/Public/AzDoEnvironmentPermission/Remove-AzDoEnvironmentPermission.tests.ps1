$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoEnvironmentPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoEnvironmentPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-AzDoPermission
        Mock -CommandName Write-Error
    }

    Context "when namespace is found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'SecurityNamespaces' { return @{ namespaceId = 'mock-ns-id' } }
                    'LiveProjects'       { return @{ id = 'mock-project-id' } }
                    'LiveAgentPools'     { return @{ id = 1 } }
                    'LiveArtifactFeeds'  { return @{ id = 'feed-id' } }
                    'LiveACLList'        { return @{} }
                    default { return @{ id = 'mock-id' } }
                }
            }
        }

        It "performs the expected operation" {
            Remove-AzDoEnvironmentPermission -ProjectName 'TestProject' -EnvironmentName 'TestEnv' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Remove-AzDoPermission -Exactly -Times 1
        }
    }

    Context "when namespace not found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error" {
            Remove-AzDoEnvironmentPermission -ProjectName 'TestProject' -EnvironmentName 'TestEnv' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }
}
