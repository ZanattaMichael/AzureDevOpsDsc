$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoAreaPermission' {


    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoAreaPermission.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }
        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # Load the summary state
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-ClassFilePath '002.LocalizedDataAzSerializationPatten')

        Mock -CommandName Get-CacheItem {
            param ([string]$Key, [string]$Type)
            if ($Key -eq 'CSS' -and $Type -eq 'SecurityNamespaces') {
                return @{ namespaceId = "12345" }
            } elseif ($Key -eq $ProjectName -and $Type -eq 'LiveProjects') {
                return @{ Name = "SampleProject" }
            } elseif ($Key -eq "12345" -and $Type -eq 'LiveACLList') {
                return @(
                    @{ token = "vstfs:///Classification/Node/1" },
                    @{ token = "vstfs:///Classification/Node/2" }
                )
            }
        }

        Mock -CommandName ConvertTo-ACLHashtable {
            return @{ SerializedACLs = "SerializedData" }
        }

        Mock -CommandName Set-AzDoPermission
        Mock -CommandName Remove-CacheItem

    }

    Context "When AreaPath is not specified" {
        It "Should write a warning and stop execution" {
            Mock -CommandName Write-Warning -Verifiable
            { Set-AzDoAreaPermission -ProjectName "TestProject" -isInherited $true } |
                Should -Not -Throw
        }
    }

    Context "When Security Namespace is not found" {

        It "Should write an error message" {

            Mock -CommandName Get-CacheItem {
                return $null
            }

            Mock Write-Error -Verifiable
            { Set-AzDoAreaPermission -ProjectName "TestProject" -AreaPath "SampleAreaPath" -isInherited $true } |
                Should -Not -Throw
        }
    }

    Context "When Project is not found" {

        It "Should write an error message" {

            Mock -CommandName Get-CacheItem {
                param ([string]$Key, [string]$Type)
                if ($Key -eq 'CSS' -and $Type -eq 'SecurityNamespaces') {
                    return @{ namespaceId = "12345" }
                } else {
                    return $null
                }
            }

            Mock Write-Error -Verifiable

            { Set-AzDoAreaPermission -ProjectName "TestProject" -AreaPath "SampleAreaPath" -isInherited $true } |
                Should -Not -Throw
        }
    }

    Context "When AreaPath is not specified" {
        It "Should set ClearACEs to true and call Set-AzDoPermission" {
            $LookupResult = @{
                identifiers = @("1")
                propertiesChanged = @{}
                DifferenceACLs = @{}
            }
            Set-AzDoAreaPermission -ProjectName "SampleProject" -isInherited $true -LookupResult $LookupResult

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly 1
        }
    }

    Context "When AreaPath is specified" {
        It "Should not set ClearACEs and call Set-AzDoPermission" {
            $LookupResult = @{
                identifiers = @("1")
                propertiesChanged = @{}
            }
            Set-AzDoAreaPermission -ProjectName "SampleProject" -AreaPath "SampleAreaPath" -isInherited $true -LookupResult $LookupResult

            Assert-MockCalled -CommandName Set-AzDoPermission -Exactly 1
        }
    }
}
