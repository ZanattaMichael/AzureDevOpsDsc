<#
    .DESCRIPTION
        This example shows how to update an existing service connection in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoServiceConnection 'UpdateAzDoServiceConnection'
        {
            Ensure           = 'Present'
            ProjectName      = 'MyProject'
            ConnectionName   = 'MyAzureServiceConnection'
            ConnectionType   = 'AzureRM'
            Description      = 'Connection to Azure subscription - updated'
            AllowAllPipelines = $false
            Authorization    = @{
                tenantId       = '00000000-0000-0000-0000-000000000000'
                servicePrincipalId = '00000000-0000-0000-0000-000000000001'
                authenticationType = 'spnKey'
            }
            Data             = @{
                subscriptionId   = '00000000-0000-0000-0000-000000000002'
                subscriptionName = 'My Azure Subscription'
            }
        }
    }
}
