$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoGroupPermission' -Tag "Unit", "GroupPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoGroupPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Write-Warning

        Mock -CommandName Get-CacheItem -MockWith {
            switch ($Type) {
                'LiveGroups'         { return @{ id = 'mockGroupId'; originId = 'mockOriginId'; name = 'mockGroupName' } }
                'LiveProjects'       { return @{ id = 'mockProjectId'; name = 'mockProjectName' } }
                'SecurityNamespaces' { return @{ namespaceId = 'mockSecurityNamespaceId' } }
            }
        }

        Mock -CommandName Get-DevOpsACL -MockWith {
            return @(
                @{
                    Token = @{ Type = 'GroupPermission'; GroupId = 'mockOriginId'; ProjectId = 'mockProjectId' }
                }
            )
        }

        Mock -CommandName ConvertTo-FormattedACL -MockWith {
            return @(
                @{
                    Token = @{ Type = 'GroupPermission'; GroupId = 'mockOriginId'; ProjectId = 'mockProjectId' }
                }
            )
        }

        Mock -CommandName ConvertTo-ACL -MockWith {
            return @{
                aces  = @{ Count = 1 }
                token = @{ Type = 'GroupPermission' }
            }
        }

        Mock -CommandName Test-ACLListforChanges -MockWith {
            return @{
                propertiesChanged = @('property1', 'property2')
                status            = 'Unchanged'
                reason            = 'No changes detected'
            }
        }
    }

    It 'Should return group result with correct properties when valid GroupName is provided' {
        $result = Get-AzDoGroupPermission -GroupName 'Project\Group' -isInherited $true

        $result | Should -Not -BeNullOrEmpty
        $result.project | Should -Be 'Project'
        $result.groupName | Should -Be 'Group'
        $result.propertiesChanged | Should -Contain 'property1'
        $result.status | Should -Be 'Unchanged'
    }

    It 'Should not throw an error when GroupName is invalid' {
        $result = Get-AzDoGroupPermission -GroupName 'InvalidGroupName' -isInherited $true
        $result | Should -BeNullOrEmpty
    }

    It 'Should return NotFound status when no ACEs found for the group' {
        Mock -CommandName ConvertTo-ACL -MockWith {
            return @{ aces = @{ Count = 0 } }
        }

        $result = Get-AzDoGroupPermission -GroupName 'Project\Group' -isInherited $true
        $result | Should -Not -BeNullOrEmpty
        $result.status | Should -Be ([DSCGetSummaryState]::NotFound)
    }
}
