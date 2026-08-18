<# .DESCRIPTION Creates an agent queue linked to an agent pool. #>
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'
Configuration Example {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    node localhost {
        AzDoAgentQueue 'AddAgentQueue' { Ensure='Present'; ProjectName='MyProject'; QueueName='MyQueue'; PoolName='MyAgentPool' }
    }
}