Describe "AzDoOrganizationPermission Integration Tests" -Tag "Integration", "OrganizationPermission" {

    BeforeAll {

        $GROUPNAME = 'OrgPermGroup'

        # Organization permissions apply to the whole organization, so grant them to a group made for
        # this test and nothing else. Teardown removes non-system groups.
        $body = @{ displayName = $GROUPNAME; description = 'Group for organization permission testing' } | ConvertTo-Json
        try
        {
            $null = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$(Resolve-TestOrg)/_apis/graph/groups?api-version=7.1-preview.1" `
                -Method Post -Headers (Resolve-TestAuthHeader) -Body $body -ContentType 'application/json'
        }
        catch { if ("$_" -notmatch '409|already exist') { throw } }

        # Reads the organization root ACL straight from the API, to check that writing one group's
        # permissions leaves every other identity's entry in place.
        function Get-RootAceCount
        {
            $org        = Resolve-TestOrg
            $headers    = Resolve-TestAuthHeader
            $namespaces = Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/securitynamespaces?api-version=7.1-preview.1" -Headers $headers
            $collection = $namespaces.value | Where-Object { $_.name -eq 'Collection' } | Select-Object -First 1
            $acls       = Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/accesscontrollists/$($collection.namespaceId)?api-version=7.1" -Headers $headers
            $root       = $acls.value | Where-Object { $_.token -match '^NAMESPACE:?$' } | Select-Object -First 1
            return @($root.acesDictionary.PSObject.Properties).Count
        }

        $aceCountBefore = Get-RootAceCount

        $parameters = @{
            Name       = 'AzDoOrganizationPermission'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                GroupName   = "[]\$GROUPNAME"
                Permissions = @(
                    @{
                        Identity   = "[]\$GROUPNAME"
                        Permission = @{ CREATE_PROJECTS = 'Allow' }
                    }
                )
            }
        }
    }

    Context "Testing if organization permissions exist" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (permissions not yet set)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Setting organization permissions" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after setting permissions" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should keep every other identity's entry on the organization root" {
            # At least as many as before: an ACE left by an earlier, interrupted run is already
            # counted in the baseline. A write that dropped the other identities would leave one.
            (Get-RootAceCount) | Should -BeGreaterOrEqual $aceCountBefore
        }
    }

    Context "Changing organization permissions (drift and fix)" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity   = "[]\$GROUPNAME"
                    Permission = @{ CREATE_PROJECTS = 'Deny' }
                }
            )
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after changing permissions" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing organization permissions (Ensure = Absent)" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Ensure = 'Absent'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should clear only this group's entry" {
            Start-Sleep -Seconds 5
            # This group's entry may have been in the baseline (see above), so allow for one fewer.
            (Get-RootAceCount) | Should -BeGreaterOrEqual ($aceCountBefore - 1)
        }

        It "Should report the permissions as absent" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }
}

# The Describe above counts entries on the organization root. These compare them: the root ACL is
# snapshotted before any write, and after each Set every entry that does not belong to the two test
# groups must still carry exactly the allow and deny masks it had. The ACL POST replaces the whole
# ACL for a token, so an entry this resource fails to carry through is deleted for real, and on the
# organization root that includes grants every member relies on.

Describe "AzDoOrganizationPermission Integration Tests - live ACL" -Tag "Integration", "OrganizationPermission" {

    BeforeAll {

        $GROUPA = 'OrgPermLiveGroupA'
        $GROUPB = 'OrgPermLiveGroupB'

        foreach ($name in @($GROUPA, $GROUPB))
        {
            $body = @{ displayName = $name; description = 'Group for organization permission testing' } | ConvertTo-Json
            try
            {
                $null = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$(Resolve-TestOrg)/_apis/graph/groups?api-version=7.1-preview.1" `
                    -Method Post -Headers (Resolve-TestAuthHeader) -Body $body -ContentType 'application/json'
            }
            catch { if ("$_" -notmatch '409|already exist') { throw } }
        }

        $namespaces = Invoke-RestMethod -Uri "https://dev.azure.com/$(Resolve-TestOrg)/_apis/securitynamespaces?api-version=7.1-preview.1" -Headers (Resolve-TestAuthHeader)
        $collection = $namespaces.value | Where-Object { $_.name -eq 'Collection' } | Select-Object -First 1

        # Resolve the bits from the namespace rather than hard-coding them.
        function Get-ActionBit
        {
            param ([string]$Name)

            $action = $collection.actions | Where-Object { $_.name -eq $Name } | Select-Object -First 1
            if (-not $action) { throw "Action '$Name' not found in the Collection namespace. Actions: $($collection.actions.name -join ', ')" }
            return [int64]$action.bit
        }

        function Get-ActionDisplayName
        {
            param ([string]$Name)
            return ($collection.actions | Where-Object { $_.name -eq $Name } | Select-Object -First 1).displayName
        }

        $CREATE_BIT = Get-ActionBit 'CREATE_PROJECTS'
        $TRACE_BIT  = Get-ActionBit 'DIAGNOSTIC_TRACE'

        # The ACL-side descriptor ('Microsoft.TeamFoundation.Identity;S-1-9-...') of an org-level group.
        function Get-AclDescriptor
        {
            param ([string]$GroupName)

            $filter   = [Uri]::EscapeDataString("[$(Resolve-TestOrg)]\$GroupName")
            $identity = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$(Resolve-TestOrg)/_apis/identities?searchFilter=General&filterValue=$filter&queryMembership=None&api-version=7.1" -Headers (Resolve-TestAuthHeader)
            $descriptor = @($identity.value)[0].descriptor
            if (-not $descriptor) { throw "No identity found for [$(Resolve-TestOrg)]\$GroupName" }
            return $descriptor
        }

        # The organization root ACL as { Token, Inherit, Aces = @{ descriptor = 'allow/deny' } }.
        function Get-RootAcl
        {
            $acls = Invoke-RestMethod -Uri "https://dev.azure.com/$(Resolve-TestOrg)/_apis/accesscontrollists/$($collection.namespaceId)?api-version=7.1" -Headers (Resolve-TestAuthHeader)
            $root = $acls.value | Where-Object { $_.token -match '^NAMESPACE:?$' } | Select-Object -First 1

            $aces = @{}
            foreach ($entry in $root.acesDictionary.PSObject.Properties.Value)
            {
                $aces[$entry.descriptor] = '{0}/{1}' -f [int64]$entry.allow, [int64]$entry.deny
            }

            return [PSCustomObject]@{ Token = $root.token; Inherit = [bool]$root.inheritPermissions; Aces = $aces }
        }

        # The ACE of one descriptor, as @{ allow; deny }, or $null when it has none.
        function Get-RootAce
        {
            param ([string]$Descriptor)

            $value = (Get-RootAcl).Aces[$Descriptor]
            if (-not $value) { return $null }
            $parts = $value.Split('/')
            return @{ allow = [int64]$parts[0]; deny = [int64]$parts[1] }
        }

        # Every difference between two snapshots, leaving out the descriptors under test.
        function Compare-RootAcl
        {
            param ($Before, $After, [string[]]$Exclude = @())

            $differences = @()
            if ($Before.Token -ne $After.Token)     { $differences += "token '$($Before.Token)' -> '$($After.Token)'" }
            if ($Before.Inherit -ne $After.Inherit) { $differences += "inheritPermissions $($Before.Inherit) -> $($After.Inherit)" }

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

        $descriptorA = Get-AclDescriptor $GROUPA
        $descriptorB = Get-AclDescriptor $GROUPB
        $testDescriptors = @($descriptorA, $descriptorB)

        $baseline = Get-RootAcl

        function New-OrgPermissionParameters
        {
            param ([string]$GroupName, [hashtable]$Permission, [string]$Ensure = 'Present')

            return @{
                Name       = 'AzDoOrganizationPermission'
                ModuleName = 'AzureDevOpsDscNative'
                property   = @{
                    GroupName   = "[]\$GroupName"
                    Ensure      = $Ensure
                    Permissions = @(
                        @{
                            Identity   = "[]\$GroupName"
                            Permission = $Permission
                        }
                    )
                }
            }
        }

        $groupAParameters = New-OrgPermissionParameters -GroupName $GROUPA -Permission @{ CREATE_PROJECTS = 'Allow'; DIAGNOSTIC_TRACE = 'Deny' }
    }

    Context "Writing the configured bits" {

        It "Set does not throw" {
            $groupAParameters.Method = 'Set'
            { Invoke-DscResource @groupAParameters } | Should -Not -Throw
        }

        It "Writes the allow and deny bits to the group's entry on the organization root" {
            Start-Sleep -Seconds 5
            $ace = Get-RootAce $descriptorA
            $ace | Should -Not -BeNullOrEmpty
            ($ace.allow -band $CREATE_BIT) | Should -Be $CREATE_BIT
            ($ace.deny  -band $TRACE_BIT)  | Should -Be $TRACE_BIT
            ($ace.allow -band $TRACE_BIT)  | Should -Be 0
            ($ace.deny  -band $CREATE_BIT) | Should -Be 0
        }

        It "Leaves every other entry, the token and the inheritance flag exactly as they were" {
            Compare-RootAcl -Before $baseline -After (Get-RootAcl) -Exclude $testDescriptors | Should -BeNullOrEmpty
        }

        It "Test returns True" {
            $groupAParameters.Method = 'Test'
            (Invoke-DscResource @groupAParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Running Set again" {

        It "Changes nothing when the permissions are already in place" {
            $before = Get-RootAcl
            $groupAParameters.Method = 'Set'
            Invoke-DscResource @groupAParameters
            Start-Sleep -Seconds 5

            Compare-RootAcl -Before $before -After (Get-RootAcl) | Should -BeNullOrEmpty
        }
    }

    Context "Managing a second group" {

        BeforeAll {
            $groupBParameters = New-OrgPermissionParameters -GroupName $GROUPB -Permission @{ CREATE_PROJECTS = 'Deny' }
            $groupABefore = Get-RootAce $descriptorA
        }

        It "Writes the second group's entry" {
            $groupBParameters.Method = 'Set'
            { Invoke-DscResource @groupBParameters } | Should -Not -Throw
            Start-Sleep -Seconds 5

            $ace = Get-RootAce $descriptorB
            ($ace.deny -band $CREATE_BIT) | Should -Be $CREATE_BIT
        }

        It "Leaves the first group's entry as it was" {
            $ace = Get-RootAce $descriptorA
            $ace.allow | Should -Be $groupABefore.allow
            $ace.deny  | Should -Be $groupABefore.deny
        }

        It "Test still returns True for both groups" {
            $groupAParameters.Method = 'Test'
            (Invoke-DscResource @groupAParameters).InDesiredState | Should -BeTrue
            $groupBParameters.Method = 'Test'
            (Invoke-DscResource @groupBParameters).InDesiredState | Should -BeTrue
        }

        It "Still leaves every other entry as it was" {
            Compare-RootAcl -Before $baseline -After (Get-RootAcl) -Exclude $testDescriptors | Should -BeNullOrEmpty
        }
    }

    Context "Drift made outside DSC" {

        BeforeAll {
            # Drop the deny bit the way the UI would: replace the group's entry with an allow-only one.
            $body = @{
                token                = $baseline.Token
                merge                = $false
                accessControlEntries = @(
                    @{ descriptor = $descriptorA; allow = $CREATE_BIT; deny = 0; extendedInfo = @{} }
                )
            } | ConvertTo-Json -Depth 5

            $null = Invoke-RestMethod -Uri "https://dev.azure.com/$(Resolve-TestOrg)/_apis/accesscontrolentries/$($collection.namespaceId)?api-version=7.1" `
                -Method Post -Headers (Resolve-TestAuthHeader) -Body $body -ContentType 'application/json'
            Start-Sleep -Seconds 5
        }

        It "Test reports the drift" {
            $groupAParameters.Method = 'Test'
            (Invoke-DscResource @groupAParameters).InDesiredState | Should -BeFalse
        }

        It "Set restores the deny bit" {
            $groupAParameters.Method = 'Set'
            { Invoke-DscResource @groupAParameters } | Should -Not -Throw
            Start-Sleep -Seconds 5

            $ace = Get-RootAce $descriptorA
            ($ace.deny  -band $TRACE_BIT)  | Should -Be $TRACE_BIT
            ($ace.allow -band $CREATE_BIT) | Should -Be $CREATE_BIT
        }

        It "Test returns True again" {
            $groupAParameters.Method = 'Test'
            (Invoke-DscResource @groupAParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Permissions named by their display names" {

        It "Test treats display names the same as action names" {
            $byDisplayName = New-OrgPermissionParameters -GroupName $GROUPA -Permission @{
                (Get-ActionDisplayName 'CREATE_PROJECTS')  = 'Allow'
                (Get-ActionDisplayName 'DIAGNOSTIC_TRACE') = 'Deny'
            }
            $byDisplayName.Method = 'Test'
            (Invoke-DscResource @byDisplayName).InDesiredState | Should -BeTrue
        }
    }

    Context "Removing one group's permissions (Ensure = Absent)" {

        BeforeAll {
            $groupAAbsent = New-OrgPermissionParameters -GroupName $GROUPA -Permission @{ CREATE_PROJECTS = 'Allow'; DIAGNOSTIC_TRACE = 'Deny' } -Ensure 'Absent'
            $groupBBefore = Get-RootAce $descriptorB
        }

        It "Set does not throw" {
            $groupAAbsent.Method = 'Set'
            { Invoke-DscResource @groupAAbsent } | Should -Not -Throw
        }

        It "Removes the group's entry" {
            Start-Sleep -Seconds 5
            $ace = Get-RootAce $descriptorA
            if ($ace) { ($ace.allow + $ace.deny) | Should -Be 0 }
        }

        It "Leaves the other test group's entry as it was" {
            $ace = Get-RootAce $descriptorB
            $ace.allow | Should -Be $groupBBefore.allow
            $ace.deny  | Should -Be $groupBBefore.deny
        }

        It "Leaves every other entry as it was, and keeps the ACL" {
            $after = Get-RootAcl
            $after.Token | Should -Not -BeNullOrEmpty
            Compare-RootAcl -Before $baseline -After $after -Exclude $testDescriptors | Should -BeNullOrEmpty
        }

        It "Test returns True for Absent" {
            $groupAAbsent.Method = 'Test'
            (Invoke-DscResource @groupAAbsent).InDesiredState | Should -BeTrue
        }

        It "Running Absent again changes nothing and does not throw" {
            $before = Get-RootAcl
            $groupAAbsent.Method = 'Set'
            { Invoke-DscResource @groupAAbsent } | Should -Not -Throw
            Start-Sleep -Seconds 5
            Compare-RootAcl -Before $before -After (Get-RootAcl) | Should -BeNullOrEmpty
        }
    }

    AfterAll {
        $groupBAbsent = New-OrgPermissionParameters -GroupName $GROUPB -Permission @{ CREATE_PROJECTS = 'Deny' } -Ensure 'Absent'
        $groupBAbsent.Method = 'Set'
        try { Invoke-DscResource @groupBAbsent } catch { Write-Warning "Could not clear $GROUPB's organization permissions: $_" }
    }
}
