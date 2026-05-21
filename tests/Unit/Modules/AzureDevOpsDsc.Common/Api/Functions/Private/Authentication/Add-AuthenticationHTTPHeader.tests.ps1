$currentFile = $MyInvocation.MyCommand.Path

Describe "Add-AuthenticationHTTPHeader" -Tag "Unit", "Authentication" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Add-AuthenticationHTTPHeader.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        Mock -CommandName Update-AzManagedIdentity
        Mock -CommandName Update-AzServicePrincipal
        Mock -CommandName Update-AzServicePrincipalCertificate
        Mock -CommandName Update-AzCliToken

    }

    BeforeEach {
        # Reset the global variables before each test
        $Global:DSCAZDO_AuthenticationToken = $null
        $Global:DSCAZDO_OrganizationName = "TestOrg"
    }

    It "Throws an error when the token is null" {
        $Global:DSCAZDO_AuthenticationToken = @{
            tokenType = $null
        }
        { Add-AuthenticationHTTPHeader } | Should -Throw '*The authentication token is null*'
    }

    It "Returns header for PersonalAccessToken" {
        $Global:DSCAZDO_AuthenticationToken = [PSCustomObject]@{
            tokenType = 'PersonalAccessToken'
        }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name Get -Value { return "dummyPAT" }

        $result = Add-AuthenticationHTTPHeader
        $result | Should -Be "Authorization: Basic dummyPAT"
    }

    It "Returns header for ManagedIdentity when token is not expired" {
        $Global:DSCAZDO_AuthenticationToken = @{
            tokenType = 'ManagedIdentity'
        }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name Get -Value { return "dummyPAT" }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name isExpired -Value { return $false }

        $result = Add-AuthenticationHTTPHeader
        $result | Should -Be "Bearer dummyPAT"
    }

    It "Updates and returns header for ManagedIdentity when token is expired" {
        $Global:DSCAZDO_AuthenticationToken = @{
            tokenType = 'ManagedIdentity'
        }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name Get -Value { return "dummyPAT" }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name isExpired -Value { return $true }


        # Mock Update-AzManagedIdentity: update the global directly (as the real function does) and
        # return nothing — returning a value would leak into the caller's output stream.
        Mock -CommandName Update-AzManagedIdentity -MockWith {
            $obj = [PSCustomObject]@{ tokenType = 'ManagedIdentity' }
            $obj | Add-Member -MemberType ScriptMethod -Name Get -Value { return "newMIToken" }
            $obj | Add-Member -MemberType ScriptMethod -Name isExpired -Value { return $false }
            $Global:DSCAZDO_AuthenticationToken = $obj
        }

        $result = Add-AuthenticationHTTPHeader
        $result | Should -Be "Bearer newMIToken"
    }

    It "Returns header for ServicePrincipal when token is not expired" {
        $Global:DSCAZDO_AuthenticationToken = [PSCustomObject]@{ tokenType = 'ServicePrincipal' }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name Get -Value { return "spToken" }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name isExpired -Value { return $false }

        $result = Add-AuthenticationHTTPHeader
        $result | Should -Be "Bearer spToken"
    }

    It "Updates and returns header for ServicePrincipal when token is expired" {
        $Global:DSCAZDO_AuthenticationToken = [PSCustomObject]@{ tokenType = 'ServicePrincipal' }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name Get -Value { return "spToken" }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name isExpired -Value { return $true }

        Mock -CommandName Update-AzServicePrincipal -MockWith {
            $obj = [PSCustomObject]@{ tokenType = 'ServicePrincipal' }
            $obj | Add-Member -MemberType ScriptMethod -Name Get -Value { return "newSpToken" }
            $obj | Add-Member -MemberType ScriptMethod -Name isExpired -Value { return $false }
            return $obj
        }

        $result = Add-AuthenticationHTTPHeader
        $result | Should -Be "Bearer newSpToken"
    }

    It "Returns header for Certificate when token is not expired" {
        $Global:DSCAZDO_AuthenticationToken = [PSCustomObject]@{ tokenType = 'Certificate' }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name Get -Value { return "certToken" }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name isExpired -Value { return $false }

        $result = Add-AuthenticationHTTPHeader
        $result | Should -Be "Bearer certToken"
    }

    It "Updates and returns header for Certificate when token is expired" {
        $Global:DSCAZDO_AuthenticationToken = [PSCustomObject]@{ tokenType = 'Certificate' }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name Get -Value { return "certToken" }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name isExpired -Value { return $true }

        Mock -CommandName Update-AzServicePrincipalCertificate -MockWith {
            $obj = [PSCustomObject]@{ tokenType = 'Certificate' }
            $obj | Add-Member -MemberType ScriptMethod -Name Get -Value { return "newCertToken" }
            $obj | Add-Member -MemberType ScriptMethod -Name isExpired -Value { return $false }
            return $obj
        }

        $result = Add-AuthenticationHTTPHeader
        $result | Should -Be "Bearer newCertToken"
    }

    It "Returns header for AzureCLI when token is not expired" {
        $Global:DSCAZDO_AuthenticationToken = [PSCustomObject]@{ tokenType = 'AzureCLI' }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name Get -Value { return "cliToken" }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name isExpired -Value { return $false }

        $result = Add-AuthenticationHTTPHeader
        $result | Should -Be "Bearer cliToken"
    }

    It "Updates and returns header for AzureCLI when token is expired" {
        $Global:DSCAZDO_AuthenticationToken = [PSCustomObject]@{ tokenType = 'AzureCLI' }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name Get -Value { return "cliToken" }
        $Global:DSCAZDO_AuthenticationToken | Add-Member -MemberType ScriptMethod -Name isExpired -Value { return $true }

        Mock -CommandName Update-AzCliToken -MockWith {
            $obj = [PSCustomObject]@{ tokenType = 'AzureCLI' }
            $obj | Add-Member -MemberType ScriptMethod -Name Get -Value { return "newCliToken" }
            $obj | Add-Member -MemberType ScriptMethod -Name isExpired -Value { return $false }
            return $obj
        }

        $result = Add-AuthenticationHTTPHeader
        $result | Should -Be "Bearer newCliToken"
    }

    It "Throws an error for unsupported token type" {
        $Global:DSCAZDO_AuthenticationToken = @{
            tokenType = 'UnsupportedToken'
            Get = { return "dummyToken" }
        }
        { Add-AuthenticationHTTPHeader } | Should -Throw '*The authentication token type is not supported*'
    }

}
