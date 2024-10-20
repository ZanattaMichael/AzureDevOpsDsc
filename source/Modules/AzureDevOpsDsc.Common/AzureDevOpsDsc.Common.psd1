@{
    RootModule = 'AzureDevOpsDsc.Common.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'caf65664-7dee-4767-a958-487c382a9f21'

    # Author of this module
    Author = 'DSC Community'

    # Company or vendor of this module
    CompanyName = 'DSC Community'

    # Copyright statement for this module
    Copyright = 'Copyright the DSC Community contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Functions used by the DSC Resources in AzureDevOpsDsc.'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(

        #
        # LCM Supporting Functions

        'Get-AzDevOpsServicesUri',
        'Get-AzDevOpsServicesApiUri',
        'Get-AzDevOpsOperation',
        'Test-AzDevOpsOperation',
        'Initialize-CacheObject',

        'New-AzDoAuthenticationProvider',
        'Get-AzDoCacheObjects',
        'AzDoAPI_0_ProjectCache',
        'AzDoAPI_1_GroupCache',
        'AzDoAPI_2_UserCache',
        'AzDoAPI_3_GroupMemberCache',

        #
        # DSC Class Based Resources
        'Get-xAzDoProject',
        'New-xAzDoProject',
        'Set-xAzDoProject',
        'Remove-xAzDoProject',
        'Test-xAzDoProject',

        'Get-xAzDoProjectGroup',
        'New-xAzDoProjectGroup',
        'Set-xAzDoProjectGroup',
        'Remove-xAzDoProjectGroup',
        'Test-xAzDoProjectGroup',

        'Get-xAzDoOrganizationGroup',
        'New-xAzDoOrganizationGroup',
        'Set-xAzDoOrganizationGroup',
        'Remove-xAzDoOrganizationGroup',
        'Test-xAzDoOrganizationGroup',

        'Get-xAzDoGroupMember',
        'New-xAzDoGroupMember',
        'Set-xAzDoGroupMember',
        'Remove-xAzDoGroupMember',
        'Test-xAzDoGroupMember'

        'Get-AzDoGitRepository',
        'New-AzDoGitRepository',
        'Remove-AzDoGitRepository',

        'Get-AzDoGitPermission',
        'New-AzDoGitPermission',
        'Remove-AzDoGitPermission',
        'Set-AzDoGitPermission',

        'Get-xAzDoGroupPermission',
        'New-xAzDoGroupPermission',
        'Remove-xAzDoGroupPermission',
        'Set-xAzDoGroupPermission',

        'Get-xAzDoProjectServices',
        'Set-xAzDoProjectServices',
        'Test-xAzDoProjectServices',
        'Remove-xAzDoProjectServices'

    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{
        } # End of PSData hashtable

    } # End of PrivateData hashtable
}

