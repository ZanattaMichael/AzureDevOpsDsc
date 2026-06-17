$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-AzDoGroupPermission' -Tag "Unit", "GroupPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoGroupPermission.tests.ps1'
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
            param ($Key, $Type)
            switch ($Type) {
                'SecurityNamespaces' { return @{ namespaceId = 'mockNamespaceId' } }
                'LiveProjects'       { return @{ id = 'mockProjectId' } }
                'LiveRepositories'   { return @{ id = 'mockRepositoryId' } }
                'LiveACLList'        { return @(
                    @{ token = 'repoV2/mockProjectId/mockRepositoryId' },
                    @{ token = 'repoV2/anotherProject/anotherRepo' }
                )}
                default { return $null }
            }
        }

        Mock -CommandName Remove-AzDoPermission -MockWith {}
    }

    It 'Should remove permissions when valid GroupName is provided' {
        Remove-AzDoGroupPermission -GroupName 'Project\Repository' -isInherited $true -Ensure 'Present' -Force:$true

        Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'Identity' -and $Type -eq 'SecurityNamespaces' } -Times 1
        Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'Project' -and $Type -eq 'LiveProjects' } -Times 1
        Assert-MockCalled -CommandName Remove-AzDoPermission -Times 1
    }

    It 'Should warn and not throw when GroupName is invalid' {
        { Remove-AzDoGroupPermission -GroupName 'InvalidGroupName' -isInherited $true } | Should -Not -Throw
        Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -like '*Invalid Group Name*' }
    }

    It 'Should handle case where no matching ACLs are found' {
        Mock -CommandName Get-CacheItem -MockWith {
            param ($Key, $Type)
            if ($Type -eq 'LiveACLList') {
                return @( @{ token = 'repoV2/anotherProject/anotherRepo' } )
            }
            return @{ namespaceId = 'mockNamespaceId'; id = 'mockProjectId' }
        }

        Remove-AzDoGroupPermission -GroupName 'Project\Repository' -isInherited $true -Ensure 'Present' -Force:$true

        Assert-MockCalled -CommandName Remove-AzDoPermission -Times 0
    }

    It 'Should not call Remove-AzDoPermission if ACL list is empty' {
        Mock -CommandName Get-CacheItem -MockWith {
            param ($Key, $Type)
            if ($Type -eq 'LiveACLList') { return @() }
            return @{ namespaceId = 'mockNamespaceId'; id = 'mockProjectId' }
        }

        Remove-AzDoGroupPermission -GroupName 'Project\Repository' -isInherited $true -Ensure 'Present' -Force:$true

        Assert-MockCalled -CommandName Remove-AzDoPermission -Times 0
    }
}
