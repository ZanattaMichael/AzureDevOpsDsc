<# .DESCRIPTION This example creates an agent pool. #>
$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT
Configuration Example {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    node localhost {
        AzDoAgentPool 'AddAgentPool' { Ensure='Present'; PoolName='MyAgentPool'; PoolType='automation'; AutoProvision=$false; AutoUpdate=$true }
    }
}