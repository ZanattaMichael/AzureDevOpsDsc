<#
    .DESCRIPTION
        This example posts to a webhook whenever code is pushed.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoServiceHook 'NotifyOnPush'
        {
            Ensure           = 'Present'
            Name             = 'notify-ci-on-push'
            ProjectName      = 'MyProject'
            PublisherId      = 'tfs'
            EventType        = 'git.push'
            ConsumerId       = 'webHooks'
            ConsumerActionId = 'httpRequest'
            ConsumerInputs   = @{ url = 'https://ci.contoso.com/hook' }
        }
    }
}
