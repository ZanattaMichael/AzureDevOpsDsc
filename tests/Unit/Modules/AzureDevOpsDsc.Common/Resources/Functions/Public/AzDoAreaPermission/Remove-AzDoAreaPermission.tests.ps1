$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoAreaPermission Tests" {


    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoAreaPermission.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load the summary state
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-ClassFilePath '002.LocalizedDataAzSerializationPatten')
        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-CacheItem {
            if ($Key -eq 'CSS' -and $Type -eq 'SecurityNamespaces') {
                return @{ namespaceId = "12345" }
            } elseif ($Type -eq 'LiveAreaNodes') {
                return @{ Name = "SampleAreaPath" }
            } elseif ($Key -eq $ProjectName -and $Type -eq 'LiveProjects') {
                return @{ Name = "SampleProject" }
            } elseif ($Key -eq "12345" -and $Type -eq 'LiveACLList') {
                return @(
                    @{ token = "vstfs:///Classification/Node/1" },
                    @{ token = "vstfs:///Classification/Node/2" }
                )
            }
        }

        Mock -CommandName Remove-AzDoPermission {}

    }

    Context "When AreaPath is not specified" {
        It "Should write a warning and stop execution" {
            Mock -CommandName Write-Warning -Verifiable
            { Remove-AzDoAreaPermission -ProjectName "TestProject" -isInherited $true } |
                Should -Not -Throw
        }
    }

    Context "When Security Namespace is not found" {

        It "Should write an error message" {

            Mock -CommandName Get-CacheItem {
                return $null
            }

            Mock Write-Error -Verifiable
            { Remove-AzDoAreaPermission -ProjectName "TestProject" -AreaPath "SampleAreaPath" -isInherited $true } |
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

            { Remove-AzDoAreaPermission -ProjectName "TestProject" -AreaPath "SampleAreaPath" -isInherited $true } |
                Should -Not -Throw
        }
    }

    Context "When ACLs exist" {
        It "Should call Remove-AzDoPermission" {
            $LookupResult = @{ propertiesChanged = @{ identifiers = @("1") } }
            Remove-AzDoAreaPermission -ProjectName "SampleProject" -AreaPath "SampleAreaPath" -isInherited $true -LookupResult $LookupResult

            Assert-MockCalled -CommandName Remove-AzDoPermission -Exactly 1
        }
    }

    Context "When ACLs do not exist" {
        BeforeAll {
            Mock -CommandName Get-CacheItem {
                param ([string]$Key, [string]$Type)
                if ($Key -eq 'CSS' -and $Type -eq 'SecurityNamespaces') {
                    return @{ namespaceId = "12345" }
                } elseif ($Key -eq "$ProjectName\Area\" -and $Type -eq 'LiveAreaNodes') {
                    return @{ Name = "SampleAreaPath" }
                } elseif ($Key -eq $ProjectName -and $Type -eq 'LiveProjects') {
                    return @{ Name = "SampleProject" }
                } elseif ($Key -eq "12345" -and $Type -eq 'LiveACLList') {
                    return @()
                }
            }
        }

        It "Should not call Remove-AzDoPermission" {
            $LookupResult = @{ propertiesChanged = @{ identifiers = @("3") } }
            Remove-AzDoAreaPermission -ProjectName "SampleProject" -AreaPath "SampleAreaPath" -isInherited $true -LookupResult $LookupResult

            Assert-MockCalled -CommandName Remove-AzDoPermission -Exactly 0
        }
    }

}
