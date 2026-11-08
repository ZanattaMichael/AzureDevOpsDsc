<#
    .DESCRIPTION
        This example puts a custom work item type onto a backlog.

        Without a behavior association a custom type exists but appears on no backlog and no
        board, which is the usual reason a newly created type seems to do nothing.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProcessWorkItemType 'Incident'
        {
            Ensure           = 'Present'
            ProcessName      = 'Contoso Agile'
            WorkItemTypeName = 'Incident'
            Color            = 'F6546A'
            Icon             = 'icon_flame'
        }

        AzDoProcessBehavior 'IncidentOnRequirements'
        {
            Ensure           = 'Present'
            ProcessName      = 'Contoso Agile'
            WorkItemTypeName = 'Incident'
            BehaviorName     = 'Stories'
            DependsOn        = '[AzDoProcessWorkItemType]Incident'
        }
    }
}
