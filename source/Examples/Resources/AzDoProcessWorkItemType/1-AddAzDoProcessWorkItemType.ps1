<#
    .DESCRIPTION
        This example adds a custom work item type to an inherited process.

        Only inherited processes can be customized - the system processes (Agile, Scrum, Basic,
        CMMI) are read-only, so an inherited process is created first.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProcess 'ContosoAgile'
        {
            Ensure            = 'Present'
            ProcessName       = 'Contoso Agile'
            ParentProcessName = 'Agile'
            Description       = 'Contoso customizations on top of Agile'
        }

        AzDoProcessWorkItemType 'Incident'
        {
            Ensure           = 'Present'
            ProcessName      = 'Contoso Agile'
            WorkItemTypeName = 'Incident'
            Description      = 'A production incident'
            Color            = 'F6546A'
            Icon             = 'icon_flame'
            DependsOn        = '[AzDoProcess]ContosoAgile'
        }
    }
}
