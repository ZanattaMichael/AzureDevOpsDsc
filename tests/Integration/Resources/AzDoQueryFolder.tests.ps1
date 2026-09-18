Describe "AzDoQueryFolder Integration Tests" -Tag "Integration", "WorkItemQuery" {

    BeforeAll {

        $PROJECTNAME = 'TEST_QUERYFOLDER'
        $FOLDERPATH  = 'Shared Queries/DSC_TEST_FOLDER'

        function Get-TestQuery {
            param([string]$ProjectName, [string]$Path)

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader
            $encoded = ($Path -split '/' | ForEach-Object { [System.Uri]::EscapeDataString($_) }) -join '/'

            try {
                return Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                    "https://dev.azure.com/{0}/{1}/_apis/wit/queries/{2}?`$expand=all&api-version=7.1" -f $org, $ProjectName, $encoded)
            } catch {
                return $null
            }
        }

        function New-TestQueryUnderFolder {
            param([string]$ProjectName, [string]$ParentPath, [string]$Name)

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader
            $encoded = ($ParentPath -split '/' | ForEach-Object { [System.Uri]::EscapeDataString($_) }) -join '/'

            $body = @{
                name = $Name
                wiql = "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = @project"
            } | ConvertTo-Json -Depth 5

            Invoke-RestMethod -Headers $hdr -Method Post -ContentType 'application/json' -Body $body -Uri (
                "https://dev.azure.com/{0}/{1}/_apis/wit/queries/{2}?api-version=7.1" -f $org, $ProjectName, $encoded)
        }

        $parameters = @{
            Name       = 'AzDoQueryFolder'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                Path        = $FOLDERPATH
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
    }

    Context "Testing if the query folder exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the query folder" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (query folder does not exist yet)" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the query folder" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when creating the query folder" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the query folder" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should exist in Azure DevOps as a folder" {
            $folder = Get-TestQuery -ProjectName $PROJECTNAME -Path $FOLDERPATH
            $folder | Should -Not -BeNullOrEmpty
            $folder.isFolder | Should -BeTrue
        }
    }

    Context "Re-testing an unchanged query folder" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should remain in the desired state when tested repeatedly" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Accepting a path written with backslashes" {

        It "Should treat a backslash-delimited path as the same folder" {
            $altParameters = @{
                Name       = 'AzDoQueryFolder'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    ProjectName = $PROJECTNAME
                    Path        = ($FOLDERPATH -replace '/', '\')
                }
            }

            (Invoke-DscResource @altParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Refusing to remove a folder that still has children" {

        BeforeAll {
            New-TestQueryUnderFolder -ProjectName $PROJECTNAME -ParentPath $FOLDERPATH -Name 'DSC_TEST_CHILD'

            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName          = $PROJECTNAME
                Path                 = $FOLDERPATH
                AllowRecursiveDelete = $false
                Ensure               = 'Absent'
            }
        }

        It "Should leave the folder in place when AllowRecursiveDelete is false" {
            # The resource writes an error rather than deleting other people's queries; the folder
            # must survive regardless of how that error surfaces through Invoke-DscResource.
            try { Invoke-DscResource @parameters } catch { }

            $folder = Get-TestQuery -ProjectName $PROJECTNAME -Path $FOLDERPATH
            $folder | Should -Not -BeNullOrEmpty
        }
    }

    Context "Removing the query folder recursively" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName          = $PROJECTNAME
                Path                 = $FOLDERPATH
                AllowRecursiveDelete = $true
                Ensure               = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the query folder" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (query folder absent is the desired state)" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should no longer exist in Azure DevOps" {
            $folder = Get-TestQuery -ProjectName $PROJECTNAME -Path $FOLDERPATH
            if ($null -ne $folder) { $folder.isDeleted | Should -BeTrue }
        }
    }
}
