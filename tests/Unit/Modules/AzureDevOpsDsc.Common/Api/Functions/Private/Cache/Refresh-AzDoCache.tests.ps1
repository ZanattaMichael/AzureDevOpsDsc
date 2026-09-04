$currentFile = $MyInvocation.MyCommand.Path

Describe "Refresh-AzDoCache Tests" -Tag "Unit", "Cache" {

    BeforeAll {

        # Set the Project
        $null = Set-Variable -Name "AzDoProject" -Value @() -Scope Global

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Refresh-AzDoCache.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        . (Get-ClassFilePath '000.CacheItem')
        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # Mock the Get-Command cmdlet to return a list of commands matching the pattern
        Mock -CommandName Get-Command -MockWith {
            @(
                [pscustomobject]@{ Name = 'AzDoAPI_CacheType1'; Source = 'AzureDevOpsDsc.Common' },
                [pscustomobject]@{ Name = 'AzDoAPI_CacheType2'; Source = 'AzureDevOpsDsc.Common' }
            )
        }

        function AzDoAPI_CacheType1 {
            param ($OrganizationName)
        }
        function AzDoAPI_CacheType2 {
            param ($OrganizationName)
        }

        # Mock the commands that would be invoked by Refresh-AzDoCache
        Mock -CommandName AzDoAPI_CacheType1
        Mock -CommandName AzDoAPI_CacheType2
        Mock -CommandName Remove-Variable
        Mock -CommandName Import-CacheObject

        # The real initializer names, for the -CacheType selection below. Only the
        # ones the narrowing is expected to reason about are declared.
        function AzDoAPI_0_ProjectCache               { param ($OrganizationName) }
        function AzDoAPI_1_GroupCache                 { param ($OrganizationName) }
        function AzDoAPI_4_GitRepositoryCache         { param ($OrganizationName) }
        function AzDoAPI_5_PermissionsCache           { param ($OrganizationName) }
        function AzDoAPI_9_DevOpsClassificationNodes  { param ($OrganizationName) }

        Mock -CommandName AzDoAPI_0_ProjectCache
        Mock -CommandName AzDoAPI_1_GroupCache
        Mock -CommandName AzDoAPI_4_GitRepositoryCache
        Mock -CommandName AzDoAPI_5_PermissionsCache
        Mock -CommandName AzDoAPI_9_DevOpsClassificationNodes

    }

    Context "When OrganizationName is provided" {
        It "Should call each caching command with the correct OrganizationName parameter" {
            $orgName = 'MyOrg'
            Refresh-AzDoCache -OrganizationName $orgName

            # Verify that Get-Command was called with the correct parameters
            Assert-MockCalled -CommandName Get-Command

            # Verify that each caching command was called with the correct OrganizationName parameter
            Assert-MockCalled -CommandName AzDoAPI_CacheType1
            Assert-MockCalled -CommandName AzDoAPI_CacheType2

        }
    }

    Context "When CacheType is provided" {

        It "Should run only the initializers that produce or derive from that cache" {

            Refresh-AzDoCache -OrganizationName 'MyOrg' -CacheType 'LiveProjects'

            # 0 produces LiveProjects; 4 and 9 consume it, so their output is stale too.
            Assert-MockCalled -CommandName AzDoAPI_0_ProjectCache -Exactly -Times 1
            Assert-MockCalled -CommandName AzDoAPI_4_GitRepositoryCache -Exactly -Times 1
            Assert-MockCalled -CommandName AzDoAPI_9_DevOpsClassificationNodes -Exactly -Times 1

            # Groups and permissions have nothing to do with projects.
            Assert-MockCalled -CommandName AzDoAPI_1_GroupCache -Exactly -Times 0
            Assert-MockCalled -CommandName AzDoAPI_5_PermissionsCache -Exactly -Times 0

            # Only the caches those initializers produce are reimported.
            Assert-MockCalled -CommandName Import-CacheObject -ParameterFilter {
                $CacheType -eq 'LiveProjects'
            }
            Assert-MockCalled -CommandName Import-CacheObject -Exactly -Times 0 -ParameterFilter {
                $CacheType -eq 'LiveGroups'
            }
        }

        It "Should fall back to a full refresh when no initializer produces the cache type" {

            Refresh-AzDoCache -OrganizationName 'MyOrg' -CacheType 'NotACacheType' -WarningAction SilentlyContinue

            # The full path runs everything Get-Command reports, not the narrowed set.
            Assert-MockCalled -CommandName AzDoAPI_CacheType1 -Exactly -Times 1
            Assert-MockCalled -CommandName AzDoAPI_CacheType2 -Exactly -Times 1
            Assert-MockCalled -CommandName AzDoAPI_0_ProjectCache -Exactly -Times 0
        }
    }

}
