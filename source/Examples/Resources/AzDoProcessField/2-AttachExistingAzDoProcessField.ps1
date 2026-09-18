<#
    .DESCRIPTION
        This example attaches an existing field to a work item type rather than creating a new one.

        Supplying FieldReferenceName addresses a field that already exists in the organization -
        including a system field such as System.Priority.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProcessField 'IncidentPriority'
        {
            Ensure             = 'Present'
            ProcessName        = 'Contoso Agile'
            WorkItemTypeName   = 'Incident'
            FieldName          = 'Priority'
            FieldReferenceName = 'Microsoft.VSTS.Common.Priority'
            IsRequired         = $true
            DefaultValue       = '2'
        }
    }
}
