$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoSecureFile" -Tag "Unit", "SecureFile" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoSecureFile.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the secure file exists" {

        BeforeEach {
            Mock -CommandName List-DevOpsSecureFiles -MockWith {
                return @(@{ id = 'sf-id-1'; name = 'signing.pfx'; properties = @{ env = 'prod' } })
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoSecureFile -ProjectName 'TestProject' -SecureFileName 'signing.pfx'
            $result.status | Should -Be 'Unchanged'
        }

        It "does not report drift when the content may have changed locally" {
            # Azure DevOps never returns a secure file's bytes, so content cannot be compared.
            # Reporting drift here would mean reporting it forever.
            $result = Get-AzDoSecureFile -ProjectName 'TestProject' -SecureFileName 'signing.pfx'
            $result.propertiesChanged | Should -Not -Contain 'Content'
        }

        It "reports drift when ForceUpload is set" {
            $result = Get-AzDoSecureFile -ProjectName 'TestProject' -SecureFileName 'signing.pfx' -ForceUpload $true
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Content'
        }

        It "reports no drift when the properties match" {
            $result = Get-AzDoSecureFile -ProjectName 'TestProject' -SecureFileName 'signing.pfx' -Properties @{ env = 'prod' }
            $result.status | Should -Be 'Unchanged'
        }

        It "reports drift when a property differs" {
            $result = Get-AzDoSecureFile -ProjectName 'TestProject' -SecureFileName 'signing.pfx' -Properties @{ env = 'dev' }
            $result.propertiesChanged | Should -Contain 'Properties.env'
        }
    }

    Context "when the secure file does not exist" {

        BeforeEach {
            Mock -CommandName List-DevOpsSecureFiles -MockWith {
                return @(@{ id = 'sf-id-1'; name = 'other.pfx' })
            }
        }

        It "returns status NotFound" {
            $result = Get-AzDoSecureFile -ProjectName 'TestProject' -SecureFileName 'signing.pfx'
            $result.status | Should -Be 'NotFound'
        }
    }
}
