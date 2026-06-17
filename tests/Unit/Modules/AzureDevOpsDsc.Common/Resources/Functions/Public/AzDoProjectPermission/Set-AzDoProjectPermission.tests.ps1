$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoProjectPermission" -Tag "Unit", "ProjectPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoProjectPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-ClassFilePath '002.LocalizedDataAzSerializationPatten')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName ConvertTo-ACLHashtable -MockWith { return @{ aces = @() } }
        Mock -CommandName Set-AzDoPermission
        Mock -CommandName Write-Error
        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    Context "when security namespace and project are found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'SecurityNamespaces' { return @{ namespaceId = 'mock-ns-id' } }
                    'LiveProjects'       { return @{ id = 'mock-project-id' } }
                    'LiveACLList'        { return @{} }
                    default { return $null }
                }
            }
        }

        It "calls ConvertTo-ACLHashtable" {
            Set-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' `
                -isInherited $false -LookupResult @{ propertiesChanged = @() }
            Assert-MockCalled -CommandName ConvertTo-ACLHashtable -Exactly -Times 1
        }

        It "calls Set-AzDoPermission" {
            Set-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' `
                -isInherited $false -LookupResult @{ propertiesChanged = @(); DifferenceACLs = @() }
            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1
        }
    }

    Context "when security namespace not found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error" {
            Set-AzDoProjectPermission -ProjectName 'TestProject' -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }
}
