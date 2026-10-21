<# .DESCRIPTION This example removes an agent pool. #>
$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT
Configuration Example {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    node localhost {
        AzDoAgentPool 'RemoveAgentPool' { Ensure='Absent'; PoolName='MyAgentPool' }
    }
}