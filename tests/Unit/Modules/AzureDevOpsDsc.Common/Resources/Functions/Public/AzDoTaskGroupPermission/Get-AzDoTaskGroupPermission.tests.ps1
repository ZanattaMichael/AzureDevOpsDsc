$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoTaskGroupPermission' -Tag "Unit", "TaskGroupPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoTaskGroupPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-FunctionItem 'Resolve-AzDoProject.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        Mock -CommandName Get-CacheItem -MockWith {
            param ($Key, $Type)
            switch ($Type) {
                'LiveProjects'       { return @{ id = 'project-id'; name = 'TestProject' } }
                'LiveTaskGroups'     { return @{ id = 'tg-id'; name = 'Deploy' } }
                'SecurityNamespaces' { return @{ namespaceId = 'mock-namespace-id' } }
                default              { return $null }
            }
        }
        Mock -CommandName Add-CacheItem
        Mock -CommandName List-DevOpsTaskGroups -MockWith { return @() }

        Mock -CommandName Get-DevOpsACL -MockWith {
            param ($OrganizationName, $SecurityDescriptorId, $Token)
            return @( @{ token = $Token; acesDictionary = @{} } )
        }

        Mock -CommandName ConvertTo-FormattedACL -MockWith {
            return @( @{ Token = @{ Type = 'TaskGroup' }; aces = @() } )
        }

        Mock -CommandName ConvertTo-ACL -MockWith {
            return @( @{ token = @{ Type = 'TaskGroup' }; aces = @() } )
        }

        Mock -CommandName Test-ACLListforChanges -MockWith {
            return @{ propertiesChanged = @(); status = 'Unchanged'; reason = 'No changes' }
        }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    Context 'when the task group is named' {

        It 'builds the {projectId}/{taskGroupId} token' {
            $result = Get-AzDoTaskGroupPermission -ProjectName 'TestProject' -TaskGroupName 'Deploy' -isInherited $true
            $result.aclToken | Should -Be 'project-id/tg-id'
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 1 -ParameterFilter { $Token -eq 'project-id/tg-id' }
            Assert-MockCalled -CommandName ConvertTo-ACL -Times 1 -ParameterFilter {
                $TokenName -eq 'project-id/tg-id' -and $SecurityNamespace -eq 'MetaTask'
            }
        }

        It 'returns the raw ACL for Set' {
            $result = Get-AzDoTaskGroupPermission -ProjectName 'TestProject' -TaskGroupName 'Deploy' -isInherited $true
            @($result.LiveACLs).Count | Should -Be 1
            $result.LiveACLs[0].token | Should -Be 'project-id/tg-id'
        }

        It 'looks the task group up live when it is not cached, and caches it' {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTaskGroups' } -MockWith { return $null }
            Mock -CommandName List-DevOpsTaskGroups -MockWith {
                return @( @{ id = 'other-id'; name = 'Other' }, @{ id = 'live-id'; name = 'Deploy' } )
            }

            $result = Get-AzDoTaskGroupPermission -ProjectName 'TestProject' -TaskGroupName 'Deploy' -isInherited $true
            $result.aclToken | Should -Be 'project-id/live-id'
            Assert-MockCalled -CommandName Add-CacheItem -Times 1 -ParameterFilter { $Key -eq 'TestProject\Deploy' -and $Type -eq 'LiveTaskGroups' }
        }

        It 'returns NotFound, with no token, when the task group does not exist' {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveTaskGroups' } -MockWith { return $null }

            $result = Get-AzDoTaskGroupPermission -ProjectName 'TestProject' -TaskGroupName 'Missing' -isInherited $true
            $result.status | Should -Be 'NotFound'
            $result.aclToken | Should -BeNullOrEmpty
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 0
        }

        It 'treats a token with no explicit ACL as an empty live state' {
            Mock -CommandName Get-DevOpsACL -MockWith { return $null }
            Mock -CommandName Test-ACLListforChanges -MockWith {
                return @{ propertiesChanged = @(); status = 'Changed'; reason = @($DifferenceACLs.Count) }
            }

            $result = Get-AzDoTaskGroupPermission -ProjectName 'TestProject' -TaskGroupName 'Deploy' -isInherited $true
            $result.status | Should -Be 'Changed'
            $result.reason | Should -Be 0
            $result.aclToken | Should -Be 'project-id/tg-id'
        }

        It 'compares only the identities it manages' {
            Mock -CommandName ConvertTo-ACL -MockWith {
                return @( @{ token = @{ Type = 'TaskGroup' }; aces = @( @{ Identity = @{ value = @{ originId = 'managed' } } } ) } )
            }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @( @{ Token = @{ Type = 'TaskGroup' }; aces = @(
                    @{ Identity = @{ value = @{ originId = 'managed' } } }
                    @{ Identity = @{ value = @{ originId = 'creator' } } }
                ) } )
            }
            Mock -CommandName Test-ACLListforChanges -MockWith {
                return @{ propertiesChanged = @(); status = 'Unchanged'; reason = @($DifferenceACLs[0].aces.Count) }
            }

            $result = Get-AzDoTaskGroupPermission -ProjectName 'TestProject' -TaskGroupName 'Deploy' -isInherited $true
            $result.reason | Should -Be 1
        }
    }

    Context 'when the task group is omitted' {

        It 'builds the project-level {projectId} token without looking up a task group' {
            $result = Get-AzDoTaskGroupPermission -ProjectName 'TestProject' -isInherited $true
            $result.aclToken | Should -Be 'project-id'
            Assert-MockCalled -CommandName List-DevOpsTaskGroups -Times 0
            Assert-MockCalled -CommandName Get-CacheItem -Times 0 -ParameterFilter { $Type -eq 'LiveTaskGroups' }
        }
    }

    Context 'when the project is not found' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'LiveProjects' } -MockWith { return $null }
        }

        It 'returns NotFound without reading ACLs' {
            $result = Get-AzDoTaskGroupPermission -ProjectName 'Gone' -TaskGroupName 'Deploy' -isInherited $true
            $result.status | Should -Be 'NotFound'
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 0
        }

        It 'returns NotFound, without throwing, when the live lookup answers 404' {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'Response status code does not indicate success: 404 (Not Found).' }
            $result = Get-AzDoTaskGroupPermission -ProjectName 'Gone' -TaskGroupName 'Deploy' -isInherited $true
            $result.status | Should -Be 'NotFound'
        }
    }

    Context 'when the security namespace is not found' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'SecurityNamespaces' } -MockWith { return $null }
            Mock -CommandName Write-Error
        }

        It 'returns Error without reading ACLs' {
            $result = Get-AzDoTaskGroupPermission -ProjectName 'TestProject' -TaskGroupName 'Deploy' -isInherited $true
            $result.status | Should -Be 'Error'
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 0
        }
    }

    Context 'when Ensure is Absent' {

        BeforeEach {
            Mock -CommandName ConvertTo-ACL -MockWith {
                return @( @{ token = @{ Type = 'TaskGroup' }; aces = @( @{ Identity = @{ value = @{ originId = 'managed' } } } ) } )
            }
            Mock -CommandName Test-ACLListforChanges -MockWith {
                return @{ propertiesChanged = @(); status = 'Changed'; reason = 'Mismatch' }
            }
        }

        It 'returns NotFound once no managed identity holds an entry, so Test passes and Remove stops' {
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @( @{ Token = @{ Type = 'TaskGroup' }; aces = @( @{ Identity = @{ value = @{ originId = 'someone-else' } } } ) } )
            }
            $result = Get-AzDoTaskGroupPermission -ProjectName 'TestProject' -TaskGroupName 'Deploy' -isInherited $true -Ensure Absent
            $result.status | Should -Be 'NotFound'
        }

        It 'keeps the compared status while a managed identity still holds an entry' {
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @( @{ Token = @{ Type = 'TaskGroup' }; aces = @( @{ Identity = @{ value = @{ originId = 'managed' } } } ) } )
            }
            $result = Get-AzDoTaskGroupPermission -ProjectName 'TestProject' -TaskGroupName 'Deploy' -isInherited $true -Ensure Absent
            $result.status | Should -Be 'Changed'
        }

        It 'does not report NotFound for Ensure Present' {
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @( @{ Token = @{ Type = 'TaskGroup' }; aces = @() } )
            }
            $result = Get-AzDoTaskGroupPermission -ProjectName 'TestProject' -TaskGroupName 'Deploy' -isInherited $true -Ensure Present
            $result.status | Should -Be 'Changed'
        }
    }
}
