$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoServicePrincipalEntitlement" -Tag "Unit", "Entitlement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoServicePrincipalEntitlement.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        $script:originId = '00000000-0000-0000-0000-000000000001'

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the service principal is in the organization with the right access level" {

        BeforeEach {
            Mock -CommandName Get-DevOpsServicePrincipalEntitlement -MockWith {
                return @{ id = 'spe-1'; accessLevel = @{ accountLicenseType = 'express' } }
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoServicePrincipalEntitlement -OriginId $script:originId -AccountLicenseType 'express'
            $result.status | Should -Be 'Unchanged'
        }

        It "carries the entitlement id" {
            $result = Get-AzDoServicePrincipalEntitlement -OriginId $script:originId -AccountLicenseType 'express'
            $result.servicePrincipalEntitlementId | Should -Be 'spe-1'
        }

        It "matches on origin id rather than display name" {
            # A rename in Entra must not make the resource think the principal is missing.
            Get-AzDoServicePrincipalEntitlement -OriginId $script:originId -DisplayName 'renamed-sp' -AccountLicenseType 'express'

            Assert-MockCalled -CommandName Get-DevOpsServicePrincipalEntitlement -Exactly -Times 1 -ParameterFilter {
                $OriginId -eq $script:originId
            }
        }
    }

    Context "when the access level differs" {

        BeforeEach {
            Mock -CommandName Get-DevOpsServicePrincipalEntitlement -MockWith {
                return @{ id = 'spe-1'; accessLevel = @{ accountLicenseType = 'stakeholder' } }
            }
        }

        It "returns status Changed" {
            $result = Get-AzDoServicePrincipalEntitlement -OriginId $script:originId -AccountLicenseType 'express'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'AccountLicenseType'
        }
    }

    Context "when the service principal is not in the organization" {

        BeforeEach {
            Mock -CommandName Get-DevOpsServicePrincipalEntitlement -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoServicePrincipalEntitlement -OriginId $script:originId -AccountLicenseType 'express'
            $result.status | Should -Be 'NotFound'
        }

        It "reports absent rather than failing when the preview endpoint is unavailable" {
            # Get-DevOpsServicePrincipalEntitlement swallows the lookup failure and returns $null,
            # so an organization without the preview API does not fail the whole configuration.
            $result = Get-AzDoServicePrincipalEntitlement -OriginId $script:originId -AccountLicenseType 'express'
            $result.Ensure | Should -Be 'Absent'
        }
    }
}
