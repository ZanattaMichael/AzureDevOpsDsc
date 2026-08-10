using module AzureDevOpsDsc

<#
    Temporary diagnostic test - NOT part of the real suite. Checks whether `using module`
    (as opposed to Import-Module or dot-sourcing) against the genuinely built module avoids the
    intermittent "Could not find type [X]" failure seen in azuredevopsdsc.tests.ps1 on GitHub
    Actions runners.
#>
Describe 'Diagnostic: class resolution via using module of the built module' {
    It 'Should resolve [ManagedIdentityToken] as a type literal' {
        { [ManagedIdentityToken] } | Should -Not -Throw
    }

    It 'Should resolve [ServicePrincipalToken] as a type literal' {
        { [ServicePrincipalToken] } | Should -Not -Throw
    }

    It 'Should resolve [CertificateToken] as a type literal' {
        { [CertificateToken] } | Should -Not -Throw
    }

    It 'Should resolve [AzureCliToken] as a type literal' {
        { [AzureCliToken] } | Should -Not -Throw
    }

    It 'Should resolve [WorkloadIdentityFederationToken] as a type literal' {
        { [WorkloadIdentityFederationToken] } | Should -Not -Throw
    }

    It 'Should resolve [AzDoGroupPermission] as a type literal' {
        { [AzDoGroupPermission] } | Should -Not -Throw
    }

    It 'Should resolve [AzDoProject] as a type literal' {
        { [AzDoProject] } | Should -Not -Throw
    }

    It 'Should resolve [AzDoProjectServices] as a type literal' {
        { [AzDoProjectServices] } | Should -Not -Throw
    }

    It 'Should resolve [AzDoAreaPermission] as a type literal' {
        { [AzDoAreaPermission] } | Should -Not -Throw
    }

    It 'Should resolve [AzDoIterationPermission] as a type literal' {
        { [AzDoIterationPermission] } | Should -Not -Throw
    }
}
