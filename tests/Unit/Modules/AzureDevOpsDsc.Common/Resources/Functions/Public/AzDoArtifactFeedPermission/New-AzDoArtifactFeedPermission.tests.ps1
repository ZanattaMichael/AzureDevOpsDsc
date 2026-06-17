$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoArtifactFeedPermission" -Tag "Unit", "ArtifactFeedPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoArtifactFeedPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsArtifactFeedPermission
        Mock -CommandName Write-Error
        Mock -CommandName Write-Verbose
    }

    Context "when feed is found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                if ($Type -eq 'LiveArtifactFeeds') { return @{ id = 'feed-id'; name = 'TestFeed' } }
                return $null
            }
        }

        It "performs the expected operation" {
            $lookupResult = @{
                feedCache          = @{ id = 'feed-id'; name = 'TestFeed' }
                livePermissions    = @()
                desiredPermissions = @([PSCustomObject]@{ role = 'reader'; identityDescriptor = 'desc-1' })
            }
            New-AzDoArtifactFeedPermission -ProjectName 'TestProject' -FeedName 'TestFeed' -LookupResult $lookupResult
            Assert-MockCalled -CommandName Set-DevOpsArtifactFeedPermission -Exactly -Times 1
        }
    }

    Context "when feed not found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error" {
            New-AzDoArtifactFeedPermission -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }
}
