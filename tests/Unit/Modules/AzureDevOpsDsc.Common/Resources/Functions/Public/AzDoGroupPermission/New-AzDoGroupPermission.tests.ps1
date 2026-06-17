$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoGroupPermission' -Tag "Unit", "GroupPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoGroupPermission.tests.ps1'
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
            param ($Key, $Type)
            switch ($Type) {
                'SecurityNamespaces' { return @{ namespaceId = 'mockNamespaceId' } }
                'LiveProjects'       { return @{ id = 'mockProjectId' } }
                'LiveGroups'         { return @{ id = 'mockGroupId' } }
                'LiveACLList'        { return @{} }
                default              { return $null }
            }
        }

        Mock -CommandName ConvertTo-ACLHashtable -MockWith {
            return @{ aces = @{ Count = 1 } }
        }

        Mock -CommandName Set-AzDoPermission
    }

    It 'Should set permissions when valid GroupName is provided' {
        $LookupResult = @{ propertiesChanged = @('property1', 'property2') }
        $Permissions  = @( @{ PermissionBit = 'Read'; DisplayName = 'Read' } )

        New-AzDoGroupPermission -GroupName 'Project\Group' -isInherited $true -Permissions $Permissions -LookupResult $LookupResult -Ensure 'Present' -Force:$true

        Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'Identity' -and $Type -eq 'SecurityNamespaces' } -Times 1
        Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter { $Key -eq 'Project' -and $Type -eq 'LiveProjects' } -Times 1
        Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter { $Key -eq '[Project]\Group' -and $Type -eq 'LiveGroups' } -Times 1
        Assert-MockCalled -CommandName ConvertTo-ACLHashtable -Times 1
        Assert-MockCalled -CommandName Set-AzDoPermission -Times 1
    }

    It 'Should warn and not throw when GroupName is invalid' {
        { New-AzDoGroupPermission -GroupName 'InvalidGroupName' -isInherited $true } | Should -Not -Throw
        Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -like '*Invalid Group Name*' }
    }

    It 'Should handle case where no LookupResult is provided' {
        New-AzDoGroupPermission -GroupName 'Project\Group' -isInherited $true -Ensure 'Present' -Force:$true

        Assert-MockCalled -CommandName ConvertTo-ACLHashtable -Times 1
        Assert-MockCalled -CommandName Set-AzDoPermission -Times 1
    }

    It 'Should always call Set-AzDoPermission after ACL serialization' {
        Mock -CommandName ConvertTo-ACLHashtable -MockWith {
            return @{ aces = @{ Count = 0 } }
        }

        $LookupResult = @{ propertiesChanged = @('property1', 'property2') }

        New-AzDoGroupPermission -GroupName 'Project\Group' -isInherited $true -LookupResult $LookupResult -Ensure 'Present' -Force:$true

        Assert-MockCalled -CommandName Set-AzDoPermission -Times 1
    }
}
