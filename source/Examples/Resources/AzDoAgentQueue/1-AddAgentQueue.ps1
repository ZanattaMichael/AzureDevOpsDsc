<# .DESCRIPTION Creates an agent queue linked to an agent pool. #>
$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT
Configuration Example {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    node localhost {
        AzDoAgentQueue 'AddAgentQueue' { Ensure='Present'; ProjectName='MyProject'; QueueName='MyQueue'; PoolName='MyAgentPool' }
    }
}