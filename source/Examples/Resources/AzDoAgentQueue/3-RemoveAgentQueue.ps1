<# .DESCRIPTION Removes an agent queue. #>
$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT
Configuration Example {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    node localhost {
        AzDoAgentQueue 'RemoveAgentQueue' { Ensure='Absent'; ProjectName='MyProject'; QueueName='MyQueue'; PoolName='MyAgentPool' }
    }
}