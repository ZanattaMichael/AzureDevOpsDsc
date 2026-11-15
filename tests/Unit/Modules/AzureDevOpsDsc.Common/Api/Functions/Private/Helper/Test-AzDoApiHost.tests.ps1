$currentFile = $MyInvocation.MyCommand.Path

Describe 'Test-AzDoApiHost' -Tag 'Unit', 'Helper', 'Security' {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Test-AzDoApiHost.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        $script:originalAllowedHosts = $env:AZDODSC_ALLOWED_API_HOSTS
    }

    BeforeEach {
        $env:AZDODSC_ALLOWED_API_HOSTS = $null
    }

    AfterAll {
        $env:AZDODSC_ALLOWED_API_HOSTS = $script:originalAllowedHosts
    }

    It 'Accepts the Azure DevOps host in <Uri>' -ForEach @(
        @{ Uri = 'https://dev.azure.com/org/_apis/projects' }
        @{ Uri = 'https://DEV.AZURE.COM/org/_apis/projects' }
        @{ Uri = 'https://dev.azure.com./org' }
        @{ Uri = 'https://vssps.dev.azure.com/org/_apis/graph/groups' }
        @{ Uri = 'https://vsrm.dev.azure.com/org' }
        @{ Uri = 'https://vsaex.dev.azure.com/org' }
        @{ Uri = 'https://feeds.dev.azure.com/org' }
        @{ Uri = 'https://auditservice.dev.azure.com/org' }
        @{ Uri = 'https://extmgmt.dev.azure.com/org' }
        @{ Uri = 'https://org.visualstudio.com/_apis/projects' }
        @{ Uri = 'https://org.vssps.visualstudio.com/_apis/graph/groups' }
    ) {
        Test-AzDoApiHost -Uri $Uri | Should -BeTrue
    }

    It 'Refuses the look-alike or foreign host in <Uri>' -ForEach @(
        @{ Uri = 'https://example.org/org/_apis/projects' }
        @{ Uri = 'https://dev.azure.com.example.org/org' }
        @{ Uri = 'https://example.org/dev.azure.com/org' }
        @{ Uri = 'https://example.org/?host=dev.azure.com' }
        @{ Uri = 'https://example.org/#dev.azure.com' }
        @{ Uri = 'https://dev.azure.com@example.org/org' }
        @{ Uri = 'https://user:pass@dev.azure.com/org' }
        @{ Uri = 'https://evildev.azure.com/org' }
        @{ Uri = 'https://dev-azure.com/org' }
        @{ Uri = 'https://azure.com/org' }
        @{ Uri = 'https://visualstudio.com/org' }
        @{ Uri = 'https://visualstudio.com.example.org/org' }
        @{ Uri = 'https://login.microsoftonline.com/tenant/oauth2/token' }
        @{ Uri = 'https://169.254.169.254/metadata' }
        @{ Uri = 'https://localhost/org' }
    ) {
        Test-AzDoApiHost -Uri $Uri | Should -BeFalse
    }

    It 'Refuses a relative URI' {
        Test-AzDoApiHost -Uri ([System.Uri]::new('/org/_apis/projects', [System.UriKind]::Relative)) | Should -BeFalse
    }

    It 'Refuses a null URI' {
        Test-AzDoApiHost -Uri $null | Should -BeFalse
    }

    Context 'AZDODSC_ALLOWED_API_HOSTS' {

        It 'Accepts a host named in the variable, whatever its case or spacing' {
            $env:AZDODSC_ALLOWED_API_HOSTS = ' TFS.Contoso.com , other.contoso.com'

            Test-AzDoApiHost -Uri 'https://tfs.contoso.com/tfs/DefaultCollection/_apis/projects' | Should -BeTrue
            Test-AzDoApiHost -Uri 'https://other.contoso.com/tfs' | Should -BeTrue
        }

        It 'Matches the named host exactly, not as a suffix or a pattern' {
            $env:AZDODSC_ALLOWED_API_HOSTS = 'tfs.contoso.com'

            Test-AzDoApiHost -Uri 'https://evil.tfs.contoso.com/tfs' | Should -BeFalse
            Test-AzDoApiHost -Uri 'https://tfs.contoso.com.example.org/tfs' | Should -BeFalse
            Test-AzDoApiHost -Uri 'https://tfsXcontoso.com/tfs' | Should -BeFalse
        }

        It 'Is not widened by an empty entry or a wildcard' {
            $env:AZDODSC_ALLOWED_API_HOSTS = ',*,;'

            Test-AzDoApiHost -Uri 'https://example.org/org' | Should -BeFalse
        }
    }
}
