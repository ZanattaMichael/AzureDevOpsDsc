<#
    .DESCRIPTION
        This example shows how to set the baseline permissions for every query in a project by
        omitting QueryPath, which targets the project's query root.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoQueryPermission 'AddProjectQueryRootPermission'
        {
            ProjectName = 'MyProject'
            isInherited = $true
            Permissions = @(
                @{
                    Identity    = '[MyProject]\Contributors'
                    Permission  = @{ Read = 'Allow' }
                }
            )
        }
    }
}
