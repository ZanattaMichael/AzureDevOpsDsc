$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoProjectPermission' -Tag "Unit", "ProjectPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoProjectPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-ClassFilePath '002.LocalizedDataAzSerializationPatten')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        Mock -CommandName Get-CacheItem -MockWith {
            param ($Key, $Type)
            switch ($Type) {
                'SecurityNamespaces' { return @{ namespaceId = 'mock-namespace-id' } }
                'LiveProjects'       { return @{ id = 'mock-project-id' } }
                'LiveACLList'        { return @{} }
                default              { return $null }
            }
        }

        Mock -CommandName ConvertTo-ACLHashtable -MockWith { return @{ aces = @() } }
        Mock -CommandName Set-AzDoPermission
    }

    It 'calls ConvertTo-ACLHashtable' {
        New-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false -LookupResult @{ propertiesChanged = @() }
        Assert-MockCalled -CommandName ConvertTo-ACLHashtable -Times 1
    }

    It 'calls Set-AzDoPermission' {
        New-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false -LookupResult @{ propertiesChanged = @() }
        Assert-MockCalled -CommandName Set-AzDoPermission -Times 1
    }

    It 'calls Get-CacheItem for SecurityNamespaces' {
        New-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false -LookupResult @{ propertiesChanged = @() }
        Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'SecurityNamespaces' } -Times 1
    }

    It 'calls Get-CacheItem for LiveProjects' {
        New-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false -LookupResult @{ propertiesChanged = @() }
        Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveProjects' } -Times 1
    }

    Context 'when security namespace is not found' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'SecurityNamespaces' } -MockWith { return $null }
            Mock -CommandName Write-Error
        }

        It 'writes an error and returns without calling Set-AzDoPermission' {
            New-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-AzDoPermission -Times 0
        }
    }

    Context 'when project is not found' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveProjects' } -MockWith { return $null }
            Mock -CommandName Write-Error
        }

        It 'writes an error and returns without calling Set-AzDoPermission' {
            New-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-AzDoPermission -Times 0
        }
    }

    Context 'verbose output' {

        It 'writes verbose output' {
            Mock -CommandName Write-Verbose -Verifiable
            New-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false -LookupResult @{ propertiesChanged = @() }
            Assert-VerifiableMock
        }
    }
}
