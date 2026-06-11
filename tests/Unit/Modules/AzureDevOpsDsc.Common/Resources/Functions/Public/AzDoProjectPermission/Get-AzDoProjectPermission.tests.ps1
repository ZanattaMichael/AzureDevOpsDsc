$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoProjectPermission' -Tag "Unit", "ProjectPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoProjectPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

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
            return @( @{ Token = 'mock-token'; ace = 'mock-ace' } )
        }

        Mock -CommandName ConvertTo-FormattedACL -MockWith {
            return @( @{ Token = @{ Type = 'ProjectPermission'; ProjectId = 'mock-project-id' }; Permission = 'Allow' } )
        }

        Mock -CommandName ConvertTo-ACL -MockWith {
            return @( @{ Token = @{ Type = 'ProjectPermission'; ProjectId = 'mock-project-id' }; Permission = 'Allow' } )
        }

        Mock -CommandName Test-ACLListforChanges -MockWith {
            return @{ propertiesChanged = @(); status = 'Unchanged'; reason = 'No changes' }
        }
    }

    Context 'when project and namespace are found' {

        It 'calls Get-DevOpsACL' {
            Get-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 1
        }

        It 'calls ConvertTo-FormattedACL' {
            Get-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName ConvertTo-FormattedACL -Times 1
        }

        It 'calls ConvertTo-ACL' {
            Get-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName ConvertTo-ACL -Times 1
        }

        It 'calls Test-ACLListforChanges' {
            Get-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Test-ACLListforChanges -Times 1
        }

        It 'returns a result with status from Test-ACLListforChanges' {
            $result = Get-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be 'Unchanged'
        }

        It 'returns Changed status when Test-ACLListforChanges reports changes' {
            Mock -CommandName Test-ACLListforChanges -MockWith {
                return @{ propertiesChanged = @('Permission'); status = 'Changed'; reason = 'Mismatch' }
            }
            $result = Get-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Permission'
        }
    }

    Context 'when project is not found' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveProjects' } -MockWith { return $null }
        }

        It 'returns status Error' {
            $result = Get-AzDoProjectPermission -ProjectName 'NonExistent' -GroupName 'TestGroup' -isInherited $false
            $result.status | Should -Be 'Error'
        }

        It 'does not call Get-DevOpsACL' {
            Get-AzDoProjectPermission -ProjectName 'NonExistent' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 0
        }
    }

    Context 'when security namespace is not found' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'SecurityNamespaces' } -MockWith { return $null }
        }

        It 'returns status Error' {
            $result = Get-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            $result.status | Should -Be 'Error'
        }

        It 'does not call Get-DevOpsACL' {
            Get-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 0
        }
    }

    Context 'when Get-DevOpsACL returns null' {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith { return $null }
        }

        It 'returns status Error' {
            $result = Get-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            $result.status | Should -Be 'Error'
        }
    }
}
