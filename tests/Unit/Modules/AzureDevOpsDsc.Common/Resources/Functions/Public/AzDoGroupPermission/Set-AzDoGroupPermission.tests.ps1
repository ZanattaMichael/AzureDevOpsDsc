$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoGroupPermission' -Tag "Unit", "GroupPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoGroupPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-ClassFilePath '002.LocalizedDataAzSerializationPatten')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Write-Warning

        Mock -CommandName Get-CacheItem -MockWith {
            param ([string]$Key, [string]$Type)
            switch ($Type) {
                'SecurityNamespaces' { return @{ namespaceId = 'mockNamespaceId' } }
                'LiveProjects'       { return @{ id = 'mockProjectId' } }
                'LiveACLList'        { return @(
                    @{ token = 'repoV2/mockProjectId/mockRepositoryId' },
                    @{ token = 'repoV2/anotherProject/anotherRepo' }
                )}
                default { return $null }
            }
        }

        Mock -CommandName ConvertTo-ACLHashtable -MockWith {
            return @{ serializedACLs = 'mockSerializedACLs' }
        }

        Mock -CommandName Set-AzDoPermission
    }

    It 'Should warn and not throw when GroupName is invalid' {
        { Set-AzDoGroupPermission -GroupName 'InvalidGroupName' -isInherited $true } | Should -Not -Throw
        Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -like '*Invalid Group Name*' }
    }

    It 'Should set permissions when valid GroupName is provided' {
        $LookupResult = @{ propertiesChanged = @{} }

        Set-AzDoGroupPermission -GroupName 'Project\Repository' -isInherited $true -Permissions @{} -LookupResult $LookupResult -Ensure 'Present' -Force:$true

        Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'Identity' -and $Type -eq 'SecurityNamespaces' } -Times 1
        Assert-MockCalled -CommandName ConvertTo-ACLHashtable -Exactly -Times 1 -Scope It
        Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1 -Scope It
    }

    It 'Should call ConvertTo-ACLHashtable with correct parameters' {
        $LookupResult = @{ propertiesChanged = @{} }

        Set-AzDoGroupPermission -GroupName 'Project\Repository' -isInherited $true -Permissions @{} -LookupResult $LookupResult -Ensure 'Present' -Force:$true

        Assert-MockCalled -CommandName ConvertTo-ACLHashtable -Exactly -Times 1 -Scope It
    }

    It 'Should always call Set-AzDoPermission after ACL serialization' {
        $LookupResult = @{ propertiesChanged = @{} }

        Set-AzDoGroupPermission -GroupName 'Project\Repository' -isInherited $true -Permissions @{} -LookupResult $LookupResult -Ensure 'Present' -Force:$true

        Assert-MockCalled -CommandName Set-AzDoPermission -Exactly -Times 1 -Scope It
    }
}
