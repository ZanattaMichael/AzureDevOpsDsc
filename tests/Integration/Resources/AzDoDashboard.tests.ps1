Describe "AzDoDashboard Integration Tests" -Tag "Integration", "Dashboard" {

    BeforeAll {

        $PROJECTNAME   = 'TEST_DASHBOARD'
        # Every project is created with a default team named '<project> Team'.
        $TEAMNAME      = "$PROJECTNAME Team"
        $DASHBOARDNAME = 'DSC Team Dashboard'

        $parameters = @{
            Name       = 'AzDoDashboard'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                DashboardName = $DASHBOARDNAME
                ProjectName   = $PROJECTNAME
                TeamName      = $TEAMNAME
                Description   = 'Created by the AzDoDashboard integration test'
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
    }

    Context "Testing if the team dashboard exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the dashboard" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (dashboard does not exist yet)" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the team dashboard" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when creating the dashboard" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the dashboard" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should remain in the desired state when tested repeatedly" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Settings not compared without being specified" {

        It "Should ignore Description and RefreshInterval when they are not set" {
            $altParameters = @{
                Name       = 'AzDoDashboard'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    DashboardName = $DASHBOARDNAME
                    ProjectName   = $PROJECTNAME
                    TeamName      = $TEAMNAME
                }
            }

            (Invoke-DscResource @altParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Drifting and fixing the description and refresh interval" {

        BeforeAll {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                DashboardName   = $DASHBOARDNAME
                ProjectName     = $PROJECTNAME
                TeamName        = $TEAMNAME
                Description     = 'Updated by the AzDoDashboard integration test'
                RefreshInterval = 5
            }
        }

        It "Should report drift" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }

        It "Should converge after Set" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should keep the description when a later update manages only the refresh interval" {
            $refreshOnly = @{
                Name       = 'AzDoDashboard'
                ModuleName = 'AzureDevOpsDscNative'
                property   = @{
                    DashboardName   = $DASHBOARDNAME
                    ProjectName     = $PROJECTNAME
                    TeamName        = $TEAMNAME
                    RefreshInterval = 0
                }
            }

            $refreshOnly.Method = 'Set'
            { Invoke-DscResource @refreshOnly } | Should -Not -Throw

            $refreshOnly.Method = 'Test'
            (Invoke-DscResource @refreshOnly).InDesiredState | Should -BeTrue

            $parameters.property.RefreshInterval = 0
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Managing a project-scoped dashboard" {

        BeforeAll {
            $projectParameters = @{
                Name       = 'AzDoDashboard'
                ModuleName = 'AzureDevOpsDscNative'
                property   = @{
                    DashboardName = 'DSC Project Dashboard'
                    ProjectName   = $PROJECTNAME
                }
            }
        }

        It "Should create the dashboard without a team" {
            $projectParameters.Method = 'Test'
            (Invoke-DscResource @projectParameters).InDesiredState | Should -BeFalse

            $projectParameters.Method = 'Set'
            { Invoke-DscResource @projectParameters } | Should -Not -Throw

            $projectParameters.Method = 'Test'
            (Invoke-DscResource @projectParameters).InDesiredState | Should -BeTrue
        }

        It "Should remove the dashboard" {
            $projectParameters.property.Ensure = 'Absent'

            $projectParameters.Method = 'Set'
            { Invoke-DscResource @projectParameters } | Should -Not -Throw

            $projectParameters.Method = 'Test'
            (Invoke-DscResource @projectParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the team dashboard" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                DashboardName = $DASHBOARDNAME
                ProjectName   = $PROJECTNAME
                TeamName      = $TEAMNAME
                Ensure        = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the dashboard" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (dashboard absent is the desired state)" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }
}

# The Contexts above drive the resource through Test and Set only. These read the dashboard back
# from the Dashboard API after each Set, so a write that Test happens to agree with but that left
# the live dashboard wrong - a cleared description, a dropped widget, a duplicate - still fails.

Describe "AzDoDashboard Integration Tests - live state" -Tag "Integration", "Dashboard" {

    BeforeAll {

        $PROJECTNAME   = 'TEST_DASHBOARD'
        $TEAMNAME      = "$PROJECTNAME Team"
        $DASHBOARDNAME = 'DSC Live State Dashboard'
        $WIDGETNAME    = 'DSC integration test note'

        New-TestProject -ProjectName $PROJECTNAME

        # The dashboards collection for the team, or for the project when -Team is not given.
        function Get-DashboardCollectionUri
        {
            param ([switch]$Team)

            $scope = [Uri]::EscapeDataString($PROJECTNAME)
            if ($Team) { $scope = '{0}/{1}' -f $scope, [Uri]::EscapeDataString($TEAMNAME) }
            return 'https://dev.azure.com/{0}/{1}/_apis/dashboard/dashboards' -f (Resolve-TestOrg), $scope
        }

        # Every dashboard with this name in the scope. On the project route only project-scoped
        # dashboards count, matching what the resource considers.
        function Get-LiveDashboards
        {
            param ([string]$Name, [switch]$Team)

            $list = Invoke-RestMethod -Uri ('{0}?api-version=7.1-preview.3' -f (Get-DashboardCollectionUri -Team:$Team)) -Headers (Resolve-TestAuthHeader)
            $matching = @($list.value | Where-Object { $_.name -eq $Name })
            if (-not $Team)
            {
                $matching = @($matching | Where-Object { ([String]$_.dashboardScope -in @('project', '2')) -or [String]::IsNullOrWhiteSpace([String]$_.groupId) })
            }
            return $matching
        }

        # The full dashboard, widgets included (the list call leaves widgets out).
        function Get-LiveDashboard
        {
            param ([string]$Name, [switch]$Team)

            $found = @(Get-LiveDashboards -Name $Name -Team:$Team)
            if ($found.Count -eq 0) { return $null }
            return Invoke-RestMethod -Uri ('{0}/{1}?api-version=7.1-preview.3' -f (Get-DashboardCollectionUri -Team:$Team), $found[0].id) -Headers (Resolve-TestAuthHeader)
        }

        $parameters = @{
            Name       = 'AzDoDashboard'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                DashboardName   = $DASHBOARDNAME
                ProjectName     = $PROJECTNAME
                TeamName        = $TEAMNAME
                Description     = 'First description'
                RefreshInterval = 5
            }
        }
    }

    Context "Writing the configured settings" {

        It "Creates the dashboard with the configured description and refresh interval" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $live = Get-LiveDashboard -Name $DASHBOARDNAME -Team
            $live | Should -Not -BeNullOrEmpty
            $live.description | Should -Be 'First description'
            [int]$live.refreshInterval | Should -Be 5
        }

        It "Creates it as a team dashboard, not a project dashboard" {
            @(Get-LiveDashboards -Name $DASHBOARDNAME).Count | Should -Be 0
        }

        It "Does not create a duplicate when Set runs again" {
            $parameters.Method = 'Set'
            Invoke-DscResource @parameters
            Invoke-DscResource @parameters

            @(Get-LiveDashboards -Name $DASHBOARDNAME -Team).Count | Should -Be 1
        }

        It "Changes only the description when only the description changes" {
            $parameters.property.Description = 'Second description'
            $parameters.Method = 'Set'
            Invoke-DscResource @parameters

            $live = Get-LiveDashboard -Name $DASHBOARDNAME -Team
            $live.description | Should -Be 'Second description'
            [int]$live.refreshInterval | Should -Be 5
            $live.name | Should -Be $DASHBOARDNAME
        }
    }

    Context "Widgets added outside DSC" {

        BeforeAll {
            $dashboard = Get-LiveDashboard -Name $DASHBOARDNAME -Team

            $widget = @{
                name            = $WIDGETNAME
                contributionId  = 'ms.vss-dashboards-web.Microsoft.VisualStudioOnline.Dashboards.MarkdownWidget'
                position        = @{ row = 1; column = 1 }
                size            = @{ rowSpan = 1; columnSpan = 2 }
                settings        = 'Added by the AzDoDashboard integration test'
                settingsVersion = @{ major = 1; minor = 0; patch = 0 }
                dashboard       = @{ eTag = $dashboard.eTag }
            } | ConvertTo-Json -Depth 5

            $widgetUri = '{0}/{1}/widgets?api-version=7.1-preview.2' -f (Get-DashboardCollectionUri -Team), $dashboard.id
            $null = Invoke-RestMethod -Uri $widgetUri -Method Post -Headers (Resolve-TestAuthHeader) -Body $widget -ContentType 'application/json'
        }

        It "Has the widget before the update" {
            @((Get-LiveDashboard -Name $DASHBOARDNAME -Team).widgets | Where-Object { $_.name -eq $WIDGETNAME }).Count | Should -Be 1
        }

        It "Keeps the widget when Set updates the dashboard" {
            $parameters.property.Description = 'Third description'
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $live = Get-LiveDashboard -Name $DASHBOARDNAME -Team
            $live.description | Should -Be 'Third description'
            @($live.widgets | Where-Object { $_.name -eq $WIDGETNAME }).Count | Should -Be 1
        }
    }

    Context "Drift made outside DSC" {

        BeforeAll {
            # Change the description the way the UI would: a PUT carrying the current eTag.
            $live = Get-LiveDashboard -Name $DASHBOARDNAME -Team
            $body = @{
                id              = $live.id
                eTag            = $live.eTag
                name            = $live.name
                description     = 'Changed outside DSC'
                refreshInterval = $live.refreshInterval
            } | ConvertTo-Json

            $putUri = '{0}/{1}?api-version=7.1-preview.3' -f (Get-DashboardCollectionUri -Team), $live.id
            $null = Invoke-RestMethod -Uri $putUri -Method Put -Headers (Resolve-TestAuthHeader) -Body $body -ContentType 'application/json'
        }

        It "Test reports the drift" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }

        It "Set restores the configured description" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw

            (Get-LiveDashboard -Name $DASHBOARDNAME -Team).description | Should -Be 'Third description'

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "A project dashboard with the same name as a team dashboard" {

        BeforeAll {
            $projectParameters = @{
                Name       = 'AzDoDashboard'
                ModuleName = 'AzureDevOpsDscNative'
                property   = @{
                    DashboardName = $DASHBOARDNAME
                    ProjectName   = $PROJECTNAME
                    Description   = 'Project-scoped twin'
                }
            }
        }

        It "Does not mistake the team dashboard for the project dashboard" {
            $projectParameters.Method = 'Test'
            (Invoke-DscResource @projectParameters).InDesiredState | Should -BeFalse
        }

        It "Creates a separate project dashboard" {
            $projectParameters.Method = 'Set'
            { Invoke-DscResource @projectParameters } | Should -Not -Throw

            $projectLive = Get-LiveDashboard -Name $DASHBOARDNAME
            $projectLive | Should -Not -BeNullOrEmpty
            $projectLive.description | Should -Be 'Project-scoped twin'

            $teamLive = Get-LiveDashboard -Name $DASHBOARDNAME -Team
            $teamLive.id | Should -Not -Be $projectLive.id
            $teamLive.description | Should -Be 'Third description'
        }

        It "Removing the project dashboard leaves the team dashboard in place" {
            $projectParameters.property.Ensure = 'Absent'
            $projectParameters.Method = 'Set'
            { Invoke-DscResource @projectParameters } | Should -Not -Throw

            @(Get-LiveDashboards -Name $DASHBOARDNAME).Count | Should -Be 0
            @(Get-LiveDashboards -Name $DASHBOARDNAME -Team).Count | Should -Be 1
        }
    }

    Context "Removing the team dashboard" {

        BeforeAll {
            $absent = @{
                Name       = 'AzDoDashboard'
                ModuleName = 'AzureDevOpsDscNative'
                property   = @{
                    DashboardName = $DASHBOARDNAME
                    ProjectName   = $PROJECTNAME
                    TeamName      = $TEAMNAME
                    Ensure        = 'Absent'
                }
            }
        }

        It "Deletes the dashboard" {
            $absent.Method = 'Set'
            { Invoke-DscResource @absent } | Should -Not -Throw

            @(Get-LiveDashboards -Name $DASHBOARDNAME -Team).Count | Should -Be 0
        }

        It "Does nothing, and does not throw, when the dashboard is already gone" {
            $absent.Method = 'Set'
            { Invoke-DscResource @absent } | Should -Not -Throw

            $absent.Method = 'Test'
            (Invoke-DscResource @absent).InDesiredState | Should -BeTrue
        }
    }
}
