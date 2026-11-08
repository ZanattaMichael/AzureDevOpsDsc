<#
    .DESCRIPTION
        This example shows how to create an Azure Resource Manager service connection in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoServiceConnection 'AddAzDoServiceConnection'
        {
            Ensure           = 'Present'
            ProjectName      = 'MyProject'
            ConnectionName   = 'MyAzureServiceConnection'
            ConnectionType   = 'AzureRM'
            Description      = 'Connection to Azure subscription'
            AllowAllPipelines = $true
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
