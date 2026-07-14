<#
.SYNOPSIS
    Reproduction attempt for a live production failure: a single identity granted permissions across
    MULTIPLE different security namespaces in one continuous LCM session.

.DESCRIPTION
    Every other integration test in this suite exercises ONE resource type in isolation, and each of
    those individually passes - including AzDoProcessPermission.tests.ps1's "specific inherited process"
    and "two identities, one mixed Allow/Deny" Contexts, which were written specifically to rule out
    those shapes as the cause of a live failure.

    In production, a single identity (an 'ENT Security Auditors' style group) is granted permissions by
    FOUR different resource types in sequence within the SAME LCM run/session:
      AzDoProjectPermission -> AzDoSecurityNamespacePermission (Build) -> AzDoProcessPermission -> AzDoIterationPermission
    All four fail to converge in production; none fail in isolation. This test reproduces that exact
    sequence - the same identity, touched by all four resource types back-to-back in one Pester session -
    to test whether the failure depends on session-level state (cache pollution, identity/descriptor
    reuse across namespaces) that a single-resource test can never exercise.

    It also re-Tests the FIRST TWO resources again at the end, after the identity has been used by the
    LATER resource types, to check whether an already-converged resource regresses once the same
    identity is reused elsewhere - a distinct failure mode from "never converges in the first place".
#>
Describe "Security Auditors multi-namespace chain (reproduction)" -Tag "Integration", "SecurityAuditorsChain" {

    BeforeAll {

        $PROJECTNAME = "TEST_SECAUD_CHAIN"
        $AUDITORS    = "ChainSecurityAuditors"
        $SECONDARY   = "ChainSecondaryGroup"

        New-TestProject -ProjectName $PROJECTNAME
        New-TestGroup -ProjectName $PROJECTNAME -GroupName $AUDITORS
        New-TestGroup -ProjectName $PROJECTNAME -GroupName $SECONDARY

        $auditorsIdentity = "[$PROJECTNAME]\$AUDITORS"

        # Mirrors 'Project Permissions - Security Auditors' exactly (single identity, mixed Allow/Deny).
        $projectPermParams = @{
            Name       = 'AzDoProjectPermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName = $PROJECTNAME
                GroupName   = $auditorsIdentity
                isInherited = $false
                Permissions = @(
                    @{
                        Identity   = $auditorsIdentity
                        Permission = @{
                            GENERIC_READ      = 'Allow'
                            VIEW_TEST_RUNS    = 'Allow'
                            GENERIC_WRITE     = 'Deny'
                            DELETE            = 'Deny'
                            WORK_ITEM_DELETE  = 'Deny'
                        }
                    }
                )
            }
        }

        # Mirrors 'Build Namespace - Security Auditors' exactly (single identity, mixed Allow/Deny).
        $buildPermParams = @{
            Name       = 'AzDoSecurityNamespacePermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                SecurityNamespace = 'Build'
                Token             = $PROJECTNAME
                GroupName         = $auditorsIdentity
                isInherited       = $false
                Permissions       = @(
                    @{
                        Identity   = $auditorsIdentity
                        Permission = @{
                            ViewBuilds          = 'Allow'
                            ViewBuildDefinition = 'Allow'
                            QueueBuilds         = 'Deny'
                        }
                    }
                )
            }
        }

        # Mirrors 'Process Administrators Permissions' exactly (two identities, one mixed Allow/Deny,
        # scoped to the project's own inherited process - not the AllProcesses root).
        $PROCESSNAME = "ITChainProcess$(Get-Random -Maximum 99999)"
        $processPermParams = @{
            Name       = 'AzDoProcessPermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProcessName = $PROCESSNAME
                isInherited = $false
                Permissions = @(
                    @{
                        Identity   = "[]\$SECONDARY"
                        Permission = @{
                            Edit                          = 'Allow'
                            ReadProcessPermissions        = 'Allow'
                            AdministerProcessPermissions  = 'Allow'
                        }
                    },
                    @{
                        Identity   = "[]\$AUDITORS"
                        Permission = @{
                            ReadProcessPermissions = 'Allow'
                            Edit                    = 'Deny'
                            Delete                  = 'Deny'
                        }
                    }
                )
            }
        }

        # Mirrors 'Sprint 1 Iteration Permissions' exactly (two identities, one mixed Allow/Deny) on the
        # project's default iteration.
        $iterationPermParams = @{
            Name       = 'AzDoIterationPermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName   = $PROJECTNAME
                IterationPath = $null
                isInherited   = $false
                Permissions   = @(
                    @{
                        Identity   = "[$PROJECTNAME]\$PROJECTNAME Team"
                        Permission = @{
                            GENERIC_READ  = 'Allow'
                            WORK_ITEM_READ  = 'Allow'
                            WORK_ITEM_WRITE = 'Allow'
                        }
                    },
                    @{
                        Identity   = $auditorsIdentity
                        Permission = @{
                            GENERIC_READ    = 'Allow'
                            WORK_ITEM_READ  = 'Allow'
                            GENERIC_WRITE   = 'Deny'
                        }
                    }
                )
            }
        }
    }

    Context "Step 1: AzDoProjectPermission grants the identity its first ACE" {

        It "Should not throw on Set" {
            $projectPermParams.Method = 'Set'
            { Invoke-DscResource @projectPermParams } | Should -Not -Throw
        }

        It "Should converge" {
            Start-Sleep -Seconds 5
            $projectPermParams.Method = 'Test'
            (Invoke-DscResource @projectPermParams).InDesiredState | Should -BeTrue
        }
    }

    Context "Step 2: AzDoSecurityNamespacePermission (Build) grants the SAME identity a second ACE" {

        It "Should not throw on Set" {
            $buildPermParams.Method = 'Set'
            { Invoke-DscResource @buildPermParams } | Should -Not -Throw
        }

        It "Should converge" {
            Start-Sleep -Seconds 5
            $buildPermParams.Method = 'Test'
            (Invoke-DscResource @buildPermParams).InDesiredState | Should -BeTrue
        }
    }

    Context "Step 3: AzDoProcessPermission grants the SAME identity a third ACE (own inherited process)" {

        BeforeAll {
            $null = Invoke-DscResource -Name 'AzDoProcess' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProcessName       = $PROCESSNAME
                ParentProcessName = 'Agile'
                Description       = 'Inherited process for the security-auditors chain reproduction'
            }
            Start-Sleep -Seconds 5
        }

        AfterAll {
            $null = Invoke-DscResource -Name 'AzDoProcess' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProcessName       = $PROCESSNAME
                ParentProcessName = 'Agile'
                Ensure            = 'Absent'
            }
        }

        It "Should not throw on Set" {
            $processPermParams.Method = 'Set'
            { Invoke-DscResource @processPermParams } | Should -Not -Throw
        }

        It "Should converge" {
            Start-Sleep -Seconds 5
            $processPermParams.Method = 'Test'
            (Invoke-DscResource @processPermParams).InDesiredState | Should -BeTrue
        }
    }

    Context "Step 4: AzDoIterationPermission grants the SAME identity a fourth ACE" {

        It "Should not throw on Set" {
            $iterationPermParams.Method = 'Set'
            { Invoke-DscResource @iterationPermParams } | Should -Not -Throw
        }

        It "Should converge" {
            Start-Sleep -Seconds 5
            $iterationPermParams.Method = 'Test'
            (Invoke-DscResource @iterationPermParams).InDesiredState | Should -BeTrue
        }
    }

    Context "Regression check: earlier resources still converge after later ones touched the same identity" {

        It "AzDoProjectPermission (Step 1) should still be in the desired state" {
            $projectPermParams.Method = 'Test'
            (Invoke-DscResource @projectPermParams).InDesiredState | Should -BeTrue
        }

        It "AzDoSecurityNamespacePermission (Step 2) should still be in the desired state" {
            $buildPermParams.Method = 'Test'
            (Invoke-DscResource @buildPermParams).InDesiredState | Should -BeTrue
        }
    }

    Context "Cleanup: revert all four resources to inherited/empty" {

        It "Reverts AzDoProjectPermission" {
            $projectPermParams.Method = 'Set'
            $projectPermParams.property.Permissions = @()
            $projectPermParams.property.isInherited  = $true
            { Invoke-DscResource @projectPermParams } | Should -Not -Throw
        }

        It "Reverts AzDoSecurityNamespacePermission" {
            $buildPermParams.Method = 'Set'
            $buildPermParams.property.Permissions = @()
            $buildPermParams.property.isInherited  = $true
            { Invoke-DscResource @buildPermParams } | Should -Not -Throw
        }

        It "Reverts AzDoIterationPermission" {
            $iterationPermParams.Method = 'Set'
            $iterationPermParams.property.Permissions = @()
            $iterationPermParams.property.isInherited  = $true
            { Invoke-DscResource @iterationPermParams } | Should -Not -Throw
        }
    }
}
