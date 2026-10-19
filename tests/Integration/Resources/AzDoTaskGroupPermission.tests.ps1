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

# The Describe above drives the resource through Test and Set. These read the MetaTask ACL for the
# project token back from the API after each Set: the exact allow and deny bits, the inheritance
# flag, and every entry that does not belong to the identities under test. They need no task group,
# so they run where classic pipeline creation is disabled.

Describe "AzDoTaskGroupPermission Integration Tests - live ACL" -Tag "Integration", "TaskGroupPermission" {

    BeforeAll {

        $PROJECTNAME = 'TEST_TASKGROUP_PERM'
        $CONTRIBUTORS = "[$PROJECTNAME]\Contributors"
        $READERS      = "[$PROJECTNAME]\Readers"

        New-TestProject -ProjectName $PROJECTNAME

        $project    = Invoke-RestMethod -Uri "https://dev.azure.com/$(Resolve-TestOrg)/_apis/projects/$PROJECTNAME`?api-version=7.1" -Headers (Resolve-TestAuthHeader)
        $namespaces = Invoke-RestMethod -Uri "https://dev.azure.com/$(Resolve-TestOrg)/_apis/securitynamespaces?api-version=7.1-preview.1" -Headers (Resolve-TestAuthHeader)
        $metaTask   = $namespaces.value | Where-Object { $_.name -eq 'MetaTask' } | Select-Object -First 1

        function Get-ActionBit
        {
            param ([string]$Name)

            $action = $metaTask.actions | Where-Object { $_.name -eq $Name } | Select-Object -First 1
            if (-not $action) { throw "Action '$Name' not found in the MetaTask namespace. Actions: $($metaTask.actions.name -join ', ')" }
            return [int64]$action.bit
        }

        $EDIT_BIT   = Get-ActionBit 'Edit'
        $DELETE_BIT = Get-ActionBit 'Delete'

        function Get-AclDescriptor
        {
            param ([string]$PrincipalName)

            $filter   = [Uri]::EscapeDataString($PrincipalName)
            $identity = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$(Resolve-TestOrg)/_apis/identities?searchFilter=General&filterValue=$filter&queryMembership=None&api-version=7.1" -Headers (Resolve-TestAuthHeader)
            $descriptor = @($identity.value)[0].descriptor
            if (-not $descriptor) { throw "No identity found for $PrincipalName" }
            return $descriptor
        }

        # The project-level MetaTask ACL ('{projectId}') as { Exists, Inherit, Aces = @{ descriptor = 'allow/deny' } }.
        function Get-ProjectAcl
        {
            $uri  = "https://dev.azure.com/$(Resolve-TestOrg)/_apis/accesscontrollists/$($metaTask.namespaceId)?token=$($project.id)&api-version=7.1"
            $acl  = (Invoke-RestMethod -Uri $uri -Headers (Resolve-TestAuthHeader)).value | Where-Object { $_.token -eq $project.id } | Select-Object -First 1

            $aces = @{}
            if ($acl)
            {
                foreach ($entry in $acl.acesDictionary.PSObject.Properties.Value)
                {
                    $aces[$entry.descriptor] = '{0}/{1}' -f [int64]$entry.allow, [int64]$entry.deny
                }
            }

            return [PSCustomObject]@{ Exists = [bool]$acl; Inherit = if ($acl) { [bool]$acl.inheritPermissions } else { $true }; Aces = $aces }
        }

        function Get-ProjectAce
        {
            param ([string]$Descriptor)

            $value = (Get-ProjectAcl).Aces[$Descriptor]
            if (-not $value) { return $null }
            $parts = $value.Split('/')
            return @{ allow = [int64]$parts[0]; deny = [int64]$parts[1] }
        }

        function Compare-ProjectAcl
        {
            param ($Before, $After, [string[]]$Exclude = @())

            $differences = @()
            $descriptors = @($Before.Aces.Keys) + @($After.Aces.Keys) | Where-Object { $_ -notin $Exclude } | Sort-Object -Unique
            foreach ($descriptor in $descriptors)
            {
                if ($Before.Aces[$descriptor] -ne $After.Aces[$descriptor])
                {
                    $differences += "$descriptor : '$($Before.Aces[$descriptor])' -> '$($After.Aces[$descriptor])'"
                }
            }
            return $differences
        }

        $contributorsDescriptor = Get-AclDescriptor $CONTRIBUTORS
        $readersDescriptor      = Get-AclDescriptor $READERS
        $testDescriptors        = @($contributorsDescriptor, $readersDescriptor)

        $baseline = Get-ProjectAcl

        $parameters = @{
            Name       = 'AzDoTaskGroupPermission'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                isInherited = $true
                Permissions = @(
                    @{ Identity = $CONTRIBUTORS; Permission = @{ Delete = 'Deny' } }
                    @{ Identity = $READERS;      Permission = @{ Edit   = 'Deny' } }
                )
            }
        }
    }

    Context "Several identities in one configuration" {

        It "Set does not throw" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Writes each identity's bits to the project token" {
            Start-Sleep -Seconds 5

            $contributors = Get-ProjectAce $contributorsDescriptor
            ($contributors.deny  -band $DELETE_BIT) | Should -Be $DELETE_BIT
            ($contributors.allow -band $DELETE_BIT) | Should -Be 0

            $readers = Get-ProjectAce $readersDescriptor
            ($readers.deny  -band $EDIT_BIT) | Should -Be $EDIT_BIT
            ($readers.allow -band $EDIT_BIT) | Should -Be 0
        }

        It "Keeps the ACL inheriting" {
            (Get-ProjectAcl).Inherit | Should -BeTrue
        }

        It "Leaves every other entry on the token as it was" {
            Compare-ProjectAcl -Before $baseline -After (Get-ProjectAcl) -Exclude $testDescriptors | Should -BeNullOrEmpty
        }

        It "Test returns True" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Drift made outside DSC" {

        BeforeAll {
            # Remove the Readers entry the way the UI would.
            $uri = "https://dev.azure.com/$(Resolve-TestOrg)/_apis/accesscontrolentries/$($metaTask.namespaceId)?token=$($project.id)&descriptors=$([Uri]::EscapeDataString($readersDescriptor))&api-version=7.1"
            $null = Invoke-RestMethod -Uri $uri -Method Delete -Headers (Resolve-TestAuthHeader)
            Start-Sleep -Seconds 5
        }

        It "Test reports the drift" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }

        It "Set restores the removed entry and keeps the other" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw
            Start-Sleep -Seconds 5

            ((Get-ProjectAce $readersDescriptor).deny -band $EDIT_BIT)        | Should -Be $EDIT_BIT
            ((Get-ProjectAce $contributorsDescriptor).deny -band $DELETE_BIT) | Should -Be $DELETE_BIT

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Changing a permission from Deny to Allow" {

        BeforeAll {
            $parameters.property.Permissions = @(
                @{ Identity = $CONTRIBUTORS; Permission = @{ Delete = 'Allow' } }
                @{ Identity = $READERS;      Permission = @{ Edit   = 'Deny' } }
            )
        }

        It "Test reports the change" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }

        It "Set moves the bit from deny to allow" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw
            Start-Sleep -Seconds 5

            $contributors = Get-ProjectAce $contributorsDescriptor
            ($contributors.allow -band $DELETE_BIT) | Should -Be $DELETE_BIT
            ($contributors.deny  -band $DELETE_BIT) | Should -Be 0
        }

        It "Test returns True" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Turning inheritance off and back on" {

        It "Set with isInherited = False stops the token inheriting" {
            $parameters.property.isInherited = $false
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw
            Start-Sleep -Seconds 5

            (Get-ProjectAcl).Inherit | Should -BeFalse

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Keeps the entries while changing inheritance" {
            ((Get-ProjectAce $contributorsDescriptor).allow -band $DELETE_BIT) | Should -Be $DELETE_BIT
            ((Get-ProjectAce $readersDescriptor).deny -band $EDIT_BIT)         | Should -Be $EDIT_BIT
        }

        It "Set with isInherited = True restores inheritance" {
            $parameters.property.isInherited = $true
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw
            Start-Sleep -Seconds 5

            (Get-ProjectAcl).Inherit | Should -BeTrue

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the permissions (Ensure = Absent)" {

        BeforeAll {
            $parameters.property.Ensure = 'Absent'
        }

        It "Set does not throw" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Removes both identities' entries" {
            Start-Sleep -Seconds 5
            foreach ($descriptor in $testDescriptors)
            {
                $ace = Get-ProjectAce $descriptor
                if ($ace) { ($ace.allow + $ace.deny) | Should -Be 0 }
            }
        }

        It "Leaves every other entry on the token as it was" {
            Compare-ProjectAcl -Before $baseline -After (Get-ProjectAcl) -Exclude $testDescriptors | Should -BeNullOrEmpty
        }

        It "Test returns True for Absent" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Running Absent again changes nothing and does not throw" {
            $before = Get-ProjectAcl
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw
            Start-Sleep -Seconds 5
            Compare-ProjectAcl -Before $before -After (Get-ProjectAcl) | Should -BeNullOrEmpty
        }
    }

    Context "A project that does not exist" {

        BeforeAll {
            $missingProject = @{
                Name       = 'AzDoTaskGroupPermission'
                ModuleName = 'AzureDevOpsDscNative'
                property   = @{
                    ProjectName = 'TEST_TASKGROUP_PERM_MISSING'
                    isInherited = $true
                    Permissions = @(
                        @{ Identity = $CONTRIBUTORS; Permission = @{ Delete = 'Deny' } }
                    )
                }
            }
        }

        It "Test returns False for Present without throwing" {
            $missingProject.Method = 'Test'
            { Invoke-DscResource @missingProject } | Should -Not -Throw
            (Invoke-DscResource @missingProject).InDesiredState | Should -BeFalse
        }

        It "Test returns True for Absent" {
            $missingProject.property.Ensure = 'Absent'
            $missingProject.Method = 'Test'
            (Invoke-DscResource @missingProject).InDesiredState | Should -BeTrue
        }
    }
}
