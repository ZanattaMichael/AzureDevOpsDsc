$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoAnalyticsPermission' -Tag "Unit", "AnalyticsPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoAnalyticsPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-FunctionItem 'Resolve-AzDoProject.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        Mock -CommandName Get-CacheItem -MockWith {
            param ($Key, $Type)
            switch ($Type) {
                'LiveProjects'      { return @{ id = 'mock-project-id'; name = 'TestProject' } }
                'SecurityNamespaces'{ return @{ namespaceId = 'mock-namespace-id' } }
                default             { return $null }
            }
        }

        Mock -CommandName Get-DevOpsACL -MockWith {
            # token must match the format built in the source: '$/{id}'
            return @( @{ token = '$/mock-project-id'; ace = 'mock-ace' } )
        }

        Mock -CommandName ConvertTo-FormattedACL -MockWith {
            return @( @{ Token = @{ Type = 'Analytics'; ProjectId = 'mock-project-id' }; Permission = 'Allow' } )
        }

        Mock -CommandName ConvertTo-ACL -MockWith {
            return @( @{ Token = @{ Type = 'Analytics'; ProjectId = 'mock-project-id' }; Permission = 'Allow' } )
        }

        Mock -CommandName Test-ACLListforChanges -MockWith {
            return @{ propertiesChanged = @(); status = 'Unchanged'; reason = 'No changes' }
        }
        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    Context 'when project and namespace are found' {

        It 'calls Get-DevOpsACL' {
            Get-AzDoAnalyticsPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 1
        }

        It 'calls ConvertTo-FormattedACL' {
            Get-AzDoAnalyticsPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName ConvertTo-FormattedACL -Times 1
        }

        It 'calls ConvertTo-ACL' {
            Get-AzDoAnalyticsPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName ConvertTo-ACL -Times 1
        }

        It 'calls Test-ACLListforChanges' {
            Get-AzDoAnalyticsPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Test-ACLListforChanges -Times 1
        }

        It 'returns a result with status from Test-ACLListforChanges' {
            $result = Get-AzDoAnalyticsPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be 'Unchanged'
        }

        It 'returns Changed status when Test-ACLListforChanges reports changes' {
            Mock -CommandName Test-ACLListforChanges -MockWith {
                return @{ propertiesChanged = @('Permission'); status = 'Changed'; reason = 'Mismatch' }
            }
            $result = Get-AzDoAnalyticsPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Permission'
        }
    }

    Context 'when project is not found' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveProjects' } -MockWith { return $null }
        }

        It 'returns status NotFound (not Missing, so Set/Remove is never invoked for an absent project)' {
            $result = Get-AzDoAnalyticsPermission -ProjectName 'NonExistent' -GroupName 'TestGroup' -isInherited $false
            $result.status | Should -Be 'NotFound'
        }

        It 'does not call Get-DevOpsACL' {
            Get-AzDoAnalyticsPermission -ProjectName 'NonExistent' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 0
        }

        It 'returns NotFound, without throwing, when the live lookup answers 404 (a deleted project)' {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'Response status code does not indicate success: 404 (Not Found).' }
            $result = Get-AzDoAnalyticsPermission -ProjectName 'NonExistent' -GroupName 'TestGroup' -isInherited $false
            $result.status | Should -Be 'NotFound'
        }

        It 'rethrows a live lookup failure that is not a 404' {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'Response status code does not indicate success: 401 (Unauthorized).' }
            { Get-AzDoAnalyticsPermission -ProjectName 'NonExistent' -GroupName 'TestGroup' -isInherited $false } | Should -Throw '*401*'
        }
    }

    Context 'when security namespace is not found' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'SecurityNamespaces' } -MockWith { return $null }
        }

        It 'returns status Error' {
            $result = Get-AzDoAnalyticsPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            $result.status | Should -Be 'Error'
        }

        It 'does not call Get-DevOpsACL' {
            Get-AzDoAnalyticsPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 0
        }
    }

    Context 'when Get-DevOpsACL returns null' {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith { return $null }
        }

        It 'returns status Error' {
            $result = Get-AzDoAnalyticsPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            $result.status | Should -Be 'Error'
        }
    }
}
