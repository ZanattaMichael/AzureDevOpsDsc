Describe "AzDoWorkItemQuery Integration Tests" -Tag "Integration", "WorkItemQuery" {

    BeforeAll {

        $PROJECTNAME = 'TEST_WORKITEMQUERY'
        $FOLDERPATH  = 'Shared Queries/DSC_TEST_QUERIES'
        $QUERYPATH   = "$FOLDERPATH/DSC_TEST_ACTIVE"

        # Deliberately written the way a person would write it in a configuration file -
        # multi-line, indented, lower-case keywords. The Queries API stores a re-formatted
        # version of this, which is what the idempotency test below is really exercising.
        $WIQL = @"
select [System.Id], [System.Title]
  from WorkItems
  where [System.TeamProject] = @project
    and [System.State] = 'Active'
"@

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

        $folderParameters = @{
            Name       = 'AzDoQueryFolder'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProjectName = $PROJECTNAME
                Path        = $FOLDERPATH
            }
        }

        $parameters = @{
            Name       = 'AzDoWorkItemQuery'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                Path        = $QUERYPATH
                Wiql        = $WIQL
                Columns     = @('System.Id', 'System.Title')
            }
        }

        New-TestProject -ProjectName $PROJECTNAME

        # The query's parent folder is a prerequisite - the query resource deliberately does not
        # create its own ancestry.
        Invoke-DscResource @folderParameters
    }

    Context "Testing if the query exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the query" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (query does not exist yet)" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the query" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when creating the query" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the query" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should exist in Azure DevOps as a query, not a folder" {
            $query = Get-TestQuery -ProjectName $PROJECTNAME -Path $QUERYPATH
            $query | Should -Not -BeNullOrEmpty
            $query.isFolder | Should -Not -BeTrue
        }

        It "Should have stored the configured columns" {
            $query = Get-TestQuery -ProjectName $PROJECTNAME -Path $QUERYPATH
            @($query.columns.referenceName) | Should -Contain 'System.Title'
        }
    }

    Context "Re-testing an unchanged query" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should report no drift even though the API reformats the stored WIQL" {
            # This is the regression guard for WIQL normalization. Without it, the API's
            # re-indented, re-cased, semicolon-terminated copy of the same statement reads as
            # drift on every single Test(), forever.
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should remain in the desired state across repeated tests" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should not have been recreated - the query id should be stable" {
            $before = (Get-TestQuery -ProjectName $PROJECTNAME -Path $QUERYPATH).id

            $parameters.Method = 'Set'
            Invoke-DscResource @parameters
            $parameters.Method = 'Test'

            (Get-TestQuery -ProjectName $PROJECTNAME -Path $QUERYPATH).id | Should -Be $before
        }
    }

    Context "Changing the WIQL" {

        BeforeAll {
            # Selects the same two columns the configuration declares below. It previously
            # selected only [System.Id] while Columns still declared System.Title, and Azure
            # DevOps derives a query's stored columns from its SELECT clause - so the query was
            # updated correctly and then compared as drifted forever, on Columns rather than on
            # WIQL. That is what failed on the first live run: 'Should detect the change',
            # 'Should apply the change' and 'Should have updated the query in place' all passed,
            # and only the Test afterwards disagreed.
            #
            # The predicate is still what changes (Active -> Closed), so the context tests what
            # it was written to test.
            $script:changedWiql = "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.State] = 'Closed'"

            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                Path        = $QUERYPATH
                Wiql        = $script:changedWiql
                Columns     = @('System.Id', 'System.Title')
            }
        }

        It "Should detect the change" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }

        It "Should apply the change without throwing" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after applying the change" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should have updated the query in place rather than recreating it" {
            $query = Get-TestQuery -ProjectName $PROJECTNAME -Path $QUERYPATH
            $query.wiql | Should -BeLike "*Closed*"
        }
    }

    Context "Removing the query" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                Path        = $QUERYPATH
                Wiql        = $script:changedWiql
                Ensure      = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the query" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (query absent is the desired state)" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }
}
