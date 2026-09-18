<#
    .DESCRIPTION
        This example adds a picklist-backed custom field to a work item type.

        The picklist is declared first: a picklist-typed field needs a list to point at, so the
        field resource depends on it.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPicklist 'Severity'
        {
            Ensure       = 'Present'
            PicklistName = 'Severity'
            Items        = @('1 - Critical', '2 - High', '3 - Medium', '4 - Low')
        }

        AzDoProcessField 'IncidentSeverity'
        {
            Ensure           = 'Present'
            ProcessName      = 'Contoso Agile'
            WorkItemTypeName = 'Incident'
            FieldName        = 'Severity'
            FieldType        = 'picklistString'
            PicklistName     = 'Severity'
            IsRequired       = $true
            DependsOn        = '[AzDoPicklist]Severity'
        }
    }
}
