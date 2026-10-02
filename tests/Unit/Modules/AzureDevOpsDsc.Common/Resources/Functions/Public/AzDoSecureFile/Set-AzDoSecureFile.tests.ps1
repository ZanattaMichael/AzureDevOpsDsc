$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoSecureFile" -Tag "Unit", "SecureFile" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoSecureFile.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Update-DevOpsSecureFile -MockWith { return @{ id = 'sf-id-1' } }
        Mock -CommandName Remove-DevOpsSecureFile -MockWith { return $true }
        Mock -CommandName New-DevOpsSecureFile -MockWith { return @{ id = 'sf-id-2'; name = 'signing.pfx' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName List-DevOpsSecureFiles -MockWith { return @(@{ id = 'sf-id-1'; name = 'signing.pfx' }) }

        $script:existingFile = Join-Path -Path $TestDrive -ChildPath 'signing.pfx'
        Set-Content -LiteralPath $script:existingFile -Value 'test-content'
    }

    Context "when only properties change" {

        It "updates the properties without replacing the file" {
            $lookup = @{ liveCache = @{ id = 'sf-id-1'; name = 'signing.pfx' } }
            Set-AzDoSecureFile -ProjectName 'TestProject' -SecureFileName 'signing.pfx' -Properties @{ env = 'prod' } -LookupResult $lookup

            Assert-MockCalled -CommandName Update-DevOpsSecureFile -Exactly -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsSecureFile -Exactly -Times 0
            Assert-MockCalled -CommandName New-DevOpsSecureFile -Exactly -Times 0
        }
    }

    Context "when ForceUpload is set" {

        It "replaces the file, since the API cannot update content in place" {
            $lookup = @{ liveCache = @{ id = 'sf-id-1'; name = 'signing.pfx' } }
            Set-AzDoSecureFile -ProjectName 'TestProject' -SecureFileName 'signing.pfx' `
                -FilePath $script:existingFile -ForceUpload $true -LookupResult $lookup

            Assert-MockCalled -CommandName Remove-DevOpsSecureFile -Exactly -Times 1
            Assert-MockCalled -CommandName New-DevOpsSecureFile -Exactly -Times 1
        }

        It "refuses to delete the existing file when the local file is missing" {
            # Deleting first and failing to upload would leave the project with no secure file
            # at all, so the missing source has to be caught before anything is removed.
            $lookup = @{ liveCache = @{ id = 'sf-id-1'; name = 'signing.pfx' } }
            Set-AzDoSecureFile -ProjectName 'TestProject' -SecureFileName 'signing.pfx' `
                -FilePath (Join-Path $TestDrive 'missing.pfx') -ForceUpload $true -LookupResult $lookup

            Assert-MockCalled -CommandName Remove-DevOpsSecureFile -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when the secure file does not exist" {

        It "reports an error rather than silently doing nothing" {
            Mock -CommandName List-DevOpsSecureFiles -MockWith { return @() }
            Set-AzDoSecureFile -ProjectName 'TestProject' -SecureFileName 'missing.pfx' -LookupResult @{}
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }
}
