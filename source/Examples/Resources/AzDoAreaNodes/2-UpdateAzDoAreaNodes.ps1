<#
    .DESCRIPTION
        This example shows how to update the area nodes in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoAreaNodes 'UpdateAzDoAreaNodes'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            AreaPaths   = @(
                'MyProject\Team Alpha'
                'MyProject\Team Alpha\Frontend'
                'MyProject\Team Alpha\Backend'
                'MyProject\Team Beta'
                'MyProject\Team Beta\QA'
            )
        }
    }
}
