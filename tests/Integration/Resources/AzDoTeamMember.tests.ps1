Describe "AzDoTeamMember Integration Tests" -Tag "Integration", "TeamMember" {

    BeforeAll {

        $PROJECTNAME = 'TEST_TEAMMEMBER'
        $TEAMNAME    = 'TESTTEAM_MEMBER'
        $GROUPNAME   = 'TESTGROUP_MEMBER'

        function New-Team { param([string]$ProjectName, [string]$TeamName)
            $null = Invoke-DscResource -Name 'AzDoTeam' -ModuleName 'AzureDevOpsDscNative' -Method 'Set' -Property @{
                ProjectName = $ProjectName
                TeamName    = $TeamName
            }
        }

        $parameters = @{
            Name       = 'AzDoTeamMember'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                TeamName    = $TEAMNAME
                MemberName  = "[$PROJECTNAME]\$GROUPNAME"
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
        New-Team -ProjectName $PROJECTNAME -TeamName $TEAMNAME
        New-TestGroup -ProjectName $PROJECTNAME -GroupName $GROUPNAME
    }

    Context "Testing if the team member exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (member not yet added)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Adding the team member" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after adding the member" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the team member" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Ensure = 'Absent'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Absent is desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Granting team administrator rights via IsTeamAdmin" {

        BeforeAll {
            # Re-add the member (the previous context removed it) and request IsTeamAdmin = $true.
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                TeamName    = $TEAMNAME
                MemberName  = "[$PROJECTNAME]\$GROUPNAME"
                IsTeamAdmin = $true
            }
            $parameters.Method = 'Set'

            # Resolve the project id, team id and the member's ACL (identity) descriptor directly via
            # REST so the ACE written by Set-DevOpsTeamAdministrator can be verified independently of
            # the module's own Get path.
            $org     = Resolve-TestOrg
            $headers = Resolve-TestAuthHeader

            $script:project = Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/projects/$PROJECTNAME`?api-version=7.1-preview.4" -Headers $headers
            $script:team    = Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/projects/$PROJECTNAME/teams/$TEAMNAME`?api-version=7.1-preview.3" -Headers $headers

            $groupDescriptor = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$org/_apis/graph/descriptors/$($script:project.id)?api-version=7.1-preview.1" -Headers $headers
            $groups = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$org/_apis/graph/groups?scopeDescriptor=$($groupDescriptor.value)&api-version=7.1-preview.1" -Headers $headers
            $script:groupSubject = $groups.value | Where-Object { $_.displayName -eq $GROUPNAME } | Select-Object -First 1

            # Storage-key (identity/ACL) descriptor - the key an Identity-namespace ACE is stored
            # under - is resolved from the graph subject descriptor via the identities endpoint, the
            # same call Get-DevOpsDescriptorIdentity makes. No $expand is needed: the identity's
            # storage-key descriptor is returned on the default (unexpanded) shape.
            $identity = Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$org/_apis/identities?subjectDescriptors=$($script:groupSubject.descriptor)&api-version=7.1-preview.1" -Headers $headers
            $script:groupAclDescriptor = $identity.value[0].descriptor

            $namespaces = Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/securitynamespaces?api-version=7.1-preview.1" -Headers $headers
            $script:identityNamespace = $namespaces.value | Where-Object { $_.name -eq 'Identity' } | Select-Object -First 1
            $script:manageMembershipBit = ($script:identityNamespace.actions | Where-Object { $_.name -eq 'ManageMembership' }).bit
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after granting team administrator rights" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should have set the ManageMembership bit on the team's ACL directly via the REST API" {
            $org     = Resolve-TestOrg
            $headers = Resolve-TestAuthHeader

            $token = '{0}\{1}' -f $script:project.id, $script:team.id
            $encodedToken = [uri]::EscapeDataString($token)
            $acl = Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/accesscontrollists/$($script:identityNamespace.namespaceId)?api-version=7.1-preview.1&token=$encodedToken" -Headers $headers

            $matchingAcl = $acl.value | Where-Object { $_.token -eq $token } | Select-Object -First 1
            $matchingAcl | Should -Not -BeNullOrEmpty

            $ace = $matchingAcl.acesDictionary.psobject.Properties | Where-Object { $_.Name -eq $script:groupAclDescriptor }
            $ace | Should -Not -BeNullOrEmpty
            ([int]$ace.Value.allow -band $script:manageMembershipBit) | Should -Be $script:manageMembershipBit
        }
    }

    Context "Revoking team administrator rights on removal" {

        BeforeAll {
            $parameters.property.Ensure = 'Absent'
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Absent is desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should no longer have the ManageMembership bit set for the removed member" {
            $org     = Resolve-TestOrg
            $headers = Resolve-TestAuthHeader

            $token = '{0}\{1}' -f $script:project.id, $script:team.id
            $encodedToken = [uri]::EscapeDataString($token)
            $acl = Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/accesscontrollists/$($script:identityNamespace.namespaceId)?api-version=7.1-preview.1&token=$encodedToken" -Headers $headers

            $matchingAcl = $acl.value | Where-Object { $_.token -eq $token } | Select-Object -First 1
            $ace = $null
            if ($matchingAcl) { $ace = $matchingAcl.acesDictionary.psobject.Properties | Where-Object { $_.Name -eq $script:groupAclDescriptor } }

            if ($ace)
            {
                ([int]$ace.Value.allow -band $script:manageMembershipBit) | Should -Be 0
            }
            else
            {
                $ace | Should -BeNullOrEmpty
            }
        }
    }
}
