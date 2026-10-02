$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoApiUri' -Tag "Unit", "Helper" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoApiUri.tests.ps1'
        }

        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'contoso' }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }
    }

    Context 'Services mapping (cloud, explicit OrganizationName)' {

        It 'resolves Core' {
            Get-AzDoApiUri -Service Core -OrganizationName 'contoso' | Should -BeExactly 'https://dev.azure.com/contoso'
        }

        It 'resolves Identity' {
            Get-AzDoApiUri -Service Identity -OrganizationName 'contoso' | Should -BeExactly 'https://vssps.dev.azure.com/contoso'
        }

        It 'resolves Entitlements' {
            Get-AzDoApiUri -Service Entitlements -OrganizationName 'contoso' | Should -BeExactly 'https://vsaex.dev.azure.com/contoso'
        }

        It 'resolves Feeds' {
            Get-AzDoApiUri -Service Feeds -OrganizationName 'contoso' | Should -BeExactly 'https://feeds.dev.azure.com/contoso'
        }

        It 'resolves Audit' {
            Get-AzDoApiUri -Service Audit -OrganizationName 'contoso' | Should -BeExactly 'https://auditservice.dev.azure.com/contoso'
        }

        It 'resolves Release' {
            Get-AzDoApiUri -Service Release -OrganizationName 'contoso' | Should -BeExactly 'https://vsrm.dev.azure.com/contoso'
        }
    }

    Context 'Organization defaulting' {

        It 'falls back to Get-AzDoOrganizationName when -OrganizationName is not supplied' {
            Get-AzDoApiUri -Service Core | Should -BeExactly 'https://dev.azure.com/contoso'
            Should -Invoke -CommandName Get-AzDoOrganizationName -Times 1 -Exactly
        }
    }

    Context 'Organization name escaping' {

        It 'escapes an organization name needing escaping, only once' {
            Get-AzDoApiUri -Service Core -OrganizationName 'contoso corp' | Should -BeExactly 'https://dev.azure.com/contoso%20corp'
        }

        It 'does not double-encode an already-escaped-looking name' {
            Get-AzDoApiUri -Service Core -OrganizationName 'contoso&co' | Should -BeExactly 'https://dev.azure.com/contoso%26co'
        }
    }

    Context '-ServerUrl (on-premise), supported services' {

        It 'returns the collection URL for Core without a trailing slash' {
            Get-AzDoApiUri -Service Core -ServerUrl 'https://tfs.contoso.com/tfs/DefaultCollection' |
                Should -BeExactly 'https://tfs.contoso.com/tfs/DefaultCollection'
        }

        It 'trims a trailing slash for Core' {
            Get-AzDoApiUri -Service Core -ServerUrl 'https://tfs.contoso.com/tfs/DefaultCollection/' |
                Should -BeExactly 'https://tfs.contoso.com/tfs/DefaultCollection'
        }

        It 'returns the collection URL for Identity' {
            Get-AzDoApiUri -Service Identity -ServerUrl 'https://tfs.contoso.com/tfs/DefaultCollection/' |
                Should -BeExactly 'https://tfs.contoso.com/tfs/DefaultCollection'
        }

        It 'returns the collection URL for Feeds' {
            Get-AzDoApiUri -Service Feeds -ServerUrl 'https://tfs.contoso.com/tfs/DefaultCollection/' |
                Should -BeExactly 'https://tfs.contoso.com/tfs/DefaultCollection'
        }

        It 'returns the collection URL for Release' {
            Get-AzDoApiUri -Service Release -ServerUrl 'https://tfs.contoso.com/tfs/DefaultCollection/' |
                Should -BeExactly 'https://tfs.contoso.com/tfs/DefaultCollection'
        }
    }

    Context '-ServerUrl (on-premise), unsupported services' {

        It 'throws for Entitlements naming the service and "not supported on Azure DevOps Server"' {
            { Get-AzDoApiUri -Service Entitlements -ServerUrl 'https://tfs.contoso.com/tfs/DefaultCollection' } |
                Should -Throw -ExpectedMessage '*Entitlements*not supported on Azure DevOps Server*'
        }

        It 'throws for Audit naming the service and "not supported on Azure DevOps Server"' {
            { Get-AzDoApiUri -Service Audit -ServerUrl 'https://tfs.contoso.com/tfs/DefaultCollection' } |
                Should -Throw -ExpectedMessage '*Audit*not supported on Azure DevOps Server*'
        }
    }

    Context 'Invalid -ServerUrl' {

        It 'throws for a relative URL' {
            { Get-AzDoApiUri -Service Core -ServerUrl '/tfs/DefaultCollection' } | Should -Throw
        }

        It 'throws for an ftp: scheme' {
            { Get-AzDoApiUri -Service Core -ServerUrl 'ftp://tfs.contoso.com/tfs/DefaultCollection' } | Should -Throw
        }

        It 'does not throw for an empty -ServerUrl (falls through to organization resolution)' {
            Get-AzDoApiUri -Service Core -ServerUrl '' -OrganizationName 'contoso' | Should -BeExactly 'https://dev.azure.com/contoso'
        }
    }

    Context 'Invalid -Service' {

        It 'rejects a service not in the ValidateSet' {
            { Get-AzDoApiUri -Service 'NotAService' -OrganizationName 'contoso' } | Should -Throw
        }
    }
}
