<#
    .DESCRIPTION
        This example adds a custom workflow state to a work item type.

        The category is what matters: boards, cumulative flow diagrams and Analytics all reason
        about categories rather than state names.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProcessState 'Triaged'
        {
            Ensure           = 'Present'
            ProcessName      = 'Contoso Agile'
            WorkItemTypeName = 'Incident'
            StateName        = 'Triaged'
            StateCategory    = 'InProgress'
            Color            = '007ACC'
            Order            = 2
        }
    }
}
