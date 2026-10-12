# The project-level Contexts need no task group. The task group Contexts create one with
# AzDoTaskGroup, which an organization that disables classic pipelines refuses (see
# AzDoTaskGroup.tests.ps1); there they are skipped rather than failed.

Describe "AzDoTaskGroupPermission Integration Tests" -Tag "Integration", "TaskGroupPermission" {

    BeforeAll {

        $PROJECTNAME   = 'TEST_TASKGROUP_PERM'
        $TASKGROUPNAME = 'TEST_TG_PERM'
        $GROUPNAME     = "[$PROJECTNAME]\Contributors"

        New-TestProject -ProjectName $PROJECTNAME
        $classicPipelinesEnabled = Enable-TestClassicPipeline -ProjectName $PROJECTNAME

        $projectParameters = @{
            Name       = 'AzDoTaskGroupPermission'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                isInherited = $true
                Permissions = @(
                    @{
                        Identity   = $GROUPNAME
                        Permission = @{ Delete = 'Deny' }
                    }
                )
            }
        }

        $taskGroupParameters = @{
            Name       = 'AzDoTaskGroupPermission'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName   = $PROJECTNAME
                TaskGroupName = $TASKGROUPNAME
                isInherited   = $true
                Permissions   = @(
                    @{
                        Identity   = $GROUPNAME
                        Permission = @{ Edit = 'Allow' }
                    }
                )
            }
        }
    }

    Context "Project-level permissions" {

        It "Test returns False before the permissions are set" {
            $projectParameters.Method = 'Test'
            (Invoke-DscResource @projectParameters).InDesiredState | Should -BeFalse
        }

        It "Set does not throw" {
            $projectParameters.Method = 'Set'
            { Invoke-DscResource @projectParameters } | Should -Not -Throw
        }

        It "Test returns True after Set" {
            Start-Sleep -Seconds 5
            $projectParameters.Method = 'Test'
            (Invoke-DscResource @projectParameters).InDesiredState | Should -BeTrue
        }

        It "Ensure = Absent clears the entry without throwing" {
            $projectParameters.Method = 'Set'
            $projectParameters.property.Ensure = 'Absent'
            { Invoke-DscResource @projectParameters } | Should -Not -Throw
        }

        It "Test returns True once the entry is cleared" {
            Start-Sleep -Seconds 5
            $projectParameters.Method = 'Test'
            (Invoke-DscResource @projectParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "A task group that does not exist" {

        It "Set throws rather than writing to a token it could not resolve" {
            $missing = @{
                Name       = 'AzDoTaskGroupPermission'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Set'
                property   = @{
                    ProjectName   = $PROJECTNAME
                    TaskGroupName = 'TEST_TG_PERM_MISSING'
                    isInherited   = $true
                    Permissions   = $taskGroupParameters.property.Permissions
                }
            }
            { Invoke-DscResource @missing } | Should -Throw
        }
    }

    Context "Task group permissions" {

        BeforeAll {
            if ($classicPipelinesEnabled)
            {
                $taskGroup = @{
                    Name       = 'AzDoTaskGroup'
                    ModuleName = 'AzureDevOpsDscNative'
                    Method     = 'Set'
                    property   = @{
                        ProjectName   = $PROJECTNAME
                        TaskGroupName = $TASKGROUPNAME
                        Description   = 'Task group for permission testing'
                        Category      = 'Build'
                        Tasks         = @(
                            @{
                                taskId      = 'd9bafed4-0b18-4f58-968d-86655b4d2ce9'
                                version     = '2.*'
                                name        = 'CmdLineStep'
                                displayName = 'Run Command'
                                enabled     = $true
                                inputs      = @{ script = 'echo hello' }
                            }
                        )
                        Inputs        = @()
                    }
                }
                Invoke-DscResource @taskGroup
            }
        }

        It "Test returns False before the permissions are set" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            $taskGroupParameters.Method = 'Test'
            (Invoke-DscResource @taskGroupParameters).InDesiredState | Should -BeFalse
        }

        It "Set does not throw" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            $taskGroupParameters.Method = 'Set'
            { Invoke-DscResource @taskGroupParameters } | Should -Not -Throw
        }

        It "Test returns True after Set" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            Start-Sleep -Seconds 5
            $taskGroupParameters.Method = 'Test'
            (Invoke-DscResource @taskGroupParameters).InDesiredState | Should -BeTrue
        }

        It "Ensure = Absent clears the entry without throwing" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            $taskGroupParameters.Method = 'Set'
            $taskGroupParameters.property.Ensure = 'Absent'
            { Invoke-DscResource @taskGroupParameters } | Should -Not -Throw
        }

        It "Test returns True once the entry is cleared" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            Start-Sleep -Seconds 5
            $taskGroupParameters.Method = 'Test'
            (Invoke-DscResource @taskGroupParameters).InDesiredState | Should -BeTrue
        }
    }
}
