$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoGroupEntitlement" -Tag "Unit", "Entitlement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoGroupEntitlement.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the licensing rule matches the desired state" {

        BeforeEach {
            Mock -CommandName Get-DevOpsGroupEntitlement -MockWith {
                return @{ id = 'ge-1'; group = @{ displayName = 'Devs' }; licenseRule = @{ accountLicenseType = 'express' } }
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoGroupEntitlement -GroupDisplayName 'Devs' -AccountLicenseType 'express'
            $result.status | Should -Be 'Unchanged'
        }

        It "carries the entitlement id so Set does not need a second lookup" {
            $result = Get-AzDoGroupEntitlement -GroupDisplayName 'Devs' -AccountLicenseType 'express'
            $result.groupEntitlementId | Should -Be 'ge-1'
        }
    }

    Context "when the access level differs" {

        BeforeEach {
            Mock -CommandName Get-DevOpsGroupEntitlement -MockWith {
                return @{ id = 'ge-1'; licenseRule = @{ accountLicenseType = 'stakeholder' } }
            }
        }

        It "returns status Changed" {
            $result = Get-AzDoGroupEntitlement -GroupDisplayName 'Devs' -AccountLicenseType 'express'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'AccountLicenseType'
        }
    }

    Context "when no rule exists for the group" {

        BeforeEach {
            Mock -CommandName Get-DevOpsGroupEntitlement -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoGroupEntitlement -GroupDisplayName 'Devs' -AccountLicenseType 'express'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when no access level is specified" {

        BeforeEach {
            Mock -CommandName Get-DevOpsGroupEntitlement -MockWith {
                return @{ id = 'ge-1'; licenseRule = @{ accountLicenseType = 'stakeholder' } }
            }
        }

        It "does not treat the existing level as drift" {
            $result = Get-AzDoGroupEntitlement -GroupDisplayName 'Devs'
            $result.status | Should -Be 'Unchanged'
        }
    }
}
