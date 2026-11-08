$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzManagedIdentityToken Tests" -Tag "Unit", "ManagedIdentity", "Authentication" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzManagedIdentityToken.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # Helpers the function calls but which are not mocked here, so the harness does not load them.
        . (Get-FunctionItem 'Get-AzDoArcTokensDirectory.ps1').FullName
        . (Get-FunctionItem 'Test-AzDoArcSecretFilePath.ps1').FullName
        . (Get-FunctionItem 'ConvertFrom-AzDoSecureString.ps1').FullName

        # Import the enums
        Import-Enums | ForEach-Object {
            . $_.FullName
        }

        # Import the classes
        . (Get-ClassFilePath '001.AuthenticationToken')
        . (Get-ClassFilePath '002.PersonalAccessToken')
        . (Get-ClassFilePath '003.ManagedIdentityToken')

        # The Windows tokens directory is built from ProgramData, which is empty on Linux hosts.
        $script:originalProgramData = $env:ProgramData
        if ([String]::IsNullOrWhiteSpace($env:ProgramData)) {
            $env:ProgramData = 'C:\ProgramData'
        }
        $script:originalIdentityEndpoint = $env:IDENTITY_ENDPOINT

        # A valid Arc endpoint and valid secret-file paths for each platform branch.
        $ArcEndpoint    = 'http://localhost:40342/metadata/identity/oauth2/token'
        $WindowsKeyFile = '{0}\AzureConnectedMachineAgent\Tokens\4f6c1d2e-9a7b-4c3d-8e1f-0a2b3c4d5e6f.key' -f $env:ProgramData
        $LinuxKeyFile   = '/var/opt/azcmagent/tokens/4f6c1d2e-9a7b-4c3d-8e1f-0a2b3c4d5e6f.key'

        Mock -CommandName Test-AzDevOpsApiHttpRequestHeader -MockWith {
            return $true
        }

        Mock -CommandName Get-AzDevOpsApiVersion -MockWith {
            return "6.0-preview.1"
        }

        Mock -CommandName New-ManagedIdentityToken -MockWith {
            return @{
                AccessToken = "fake-access-token"
                Expiry = (Get-Date).AddHours(1)
            }
        }

        Mock -CommandName Test-AzToken -MockWith { return $true }
        Mock -CommandName Get-OperatingSystemInfo -MockWith { return @{ Windows = $true; Linux = $false; MacOS = $false } }
        Mock -CommandName Test-isWindowsAdmin -MockWith { return $true }

        # Get-Content's -Raw is a FileSystem-provider dynamic parameter, and Pester resolves a mock's
        # dynamic parameters from the drive in the path it is given. A Windows secret-file path on a
        # Linux host (or vice versa) has no such drive, so the mock would bind without -Raw. A plain
        # function with the parameters the code uses is what gets mocked instead.
        function Get-Content { param ([String] $LiteralPath, [Switch] $Raw) }
        Mock -CommandName Get-Content -MockWith { return "mock-data" }

        class CustomException : Exception {
            [hashtable] $response

            CustomException($Message, $response) : base($Message) {
                $this.response = $response
            }
        }

        # Throws the Azure Arc 401 challenge naming $Realm as the secret file.
        function Invoke-MockError {
            param ([String] $Realm)

            # Create a custom WebException with a response containing headers
            $response = @{
                Headers = @{
                    wwwAuthenticate = "Basic realm=$Realm"
                }
            }

            throw [CustomException]::New("Mock Error", $response)
        }

    }

    AfterAll {
        $env:ProgramData       = $script:originalProgramData
        $env:IDENTITY_ENDPOINT = $script:originalIdentityEndpoint
    }

    Context "When Verify switch is not set" {

        BeforeAll {
            $env:IDENTITY_ENDPOINT = $null
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{
                    access_token = "fake-access-token"
                }
            }
        }

        It "should return managed identity token" {
            $result = Get-AzManagedIdentityToken -OrganizationName "Contoso"
            $result.AccessToken | Should -Be "fake-access-token"
        }
    }

    Context "When it is an Azure Arc Machine and the console is not being run as Administrator" {

        AfterAll {
            $env:IDENTITY_ENDPOINT = $null
        }

        BeforeAll {

            $env:IDENTITY_ENDPOINT = $ArcEndpoint

            Mock -CommandName Test-isWindowsAdmin -MockWith {
                return $false
            }
            Mock -CommandName Test-Path -MockWith { return $false } -ParameterFilter { $LiteralPath -like '*ModuleSettings.clixml' }
        }

        It "should warn about Administrator privileges but not throw" {
            # Azure Arc auth no longer hard-fails when not elevated; it warns and proceeds, because
            # the secret-file challenge (not process elevation) is what actually gates the request.
            Mock -CommandName Write-Warning
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ access_token = 'mock-token' } }

            { Get-AzManagedIdentityToken -OrganizationName "Contoso" } | Should -Not -Throw

            Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -like '*Administrator*' }
        }
    }

    Context "When it is an Azure Arc Machine and the console is being run as Administrator" {

        AfterAll {
            $env:IDENTITY_ENDPOINT = $null
        }

        BeforeAll {

            $env:IDENTITY_ENDPOINT = $ArcEndpoint

            Mock -CommandName Test-isWindowsAdmin -MockWith {
                return $true
            }
            Mock -CommandName Test-Path -MockWith { return $false } -ParameterFilter { $LiteralPath -like '*ModuleSettings.clixml' }

        }

        It "should not throw error" {

            Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
                $null -eq $HttpHeaders.Authorization
            } -MockWith { Invoke-MockError -Realm $WindowsKeyFile }

            Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
                $null -ne $HttpHeaders.Authorization
            } -MockWith { return @{ access_token = "mock-data" } }

            Get-AzManagedIdentityToken -OrganizationName "Contoso"
            Assert-MockCalled -CommandName Test-isWindowsAdmin
            Assert-MockCalled -CommandName Get-Content -ParameterFilter { $LiteralPath -eq $WindowsKeyFile }
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 2

        }

        It "should send the Arc endpoint the secret file content as a Basic credential" {

            Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
                $null -eq $HttpHeaders.Authorization
            } -MockWith { Invoke-MockError -Realm $WindowsKeyFile }

            Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
                $null -ne $HttpHeaders.Authorization
            } -MockWith { return @{ access_token = "mock-data" } }

            Get-AzManagedIdentityToken -OrganizationName "Contoso"

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $HttpHeaders.Authorization -eq 'Basic mock-data' -and
                $Uri -like "$ArcEndpoint*" -and
                $AzureArcAuthentication -eq $true
            }
        }
    }

    Context "When IDENTITY_ENDPOINT is not a local endpoint" {

        AfterAll {
            $env:IDENTITY_ENDPOINT = $null
        }

        BeforeAll {
            Mock -CommandName Test-Path -MockWith { return $false } -ParameterFilter { $LiteralPath -like '*ModuleSettings.clixml' }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ access_token = "mock-data" } }
        }

        It "should throw naming the endpoint and not call the endpoint for '<Endpoint>'" -TestCases @(
            @{ Endpoint = 'http://attacker.example.com:40342/metadata/identity/oauth2/token' }
            @{ Endpoint = 'http://169.254.169.254/metadata/identity/oauth2/token' }
            @{ Endpoint = 'http://localhost.example.com/metadata/identity/oauth2/token' }
            @{ Endpoint = 'http://10.0.0.5/metadata/identity/oauth2/token' }
            @{ Endpoint = 'ftp://localhost:40342/metadata/identity/oauth2/token' }
            @{ Endpoint = 'file:///var/opt/azcmagent/tokens' }
            @{ Endpoint = 'mock-url' }
            @{ Endpoint = 'localhost:40342' }
        ) {
            param ($Endpoint)

            $env:IDENTITY_ENDPOINT = $Endpoint

            { Get-AzManagedIdentityToken -OrganizationName "Contoso" } |
                Should -Throw "*IDENTITY_ENDPOINT*$Endpoint*"

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 0
            Assert-MockCalled -CommandName Get-Content -Times 0
        }

        It "should accept a local endpoint on '<Endpoint>'" -TestCases @(
            @{ Endpoint = 'http://localhost:40342/metadata/identity/oauth2/token' }
            @{ Endpoint = 'http://127.0.0.1:40342/metadata/identity/oauth2/token' }
            @{ Endpoint = 'http://[::1]:40342/metadata/identity/oauth2/token' }
            @{ Endpoint = 'https://LOCALHOST:40342/metadata/identity/oauth2/token' }
        ) {
            param ($Endpoint)

            $env:IDENTITY_ENDPOINT = $Endpoint

            { Get-AzManagedIdentityToken -OrganizationName "Contoso" } | Should -Not -Throw

            # StartsWith rather than -like: '[::1]' is a character class to a wildcard.
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                ([String]$Uri).StartsWith($Endpoint)
            }
        }
    }

    Context "When the WWW-Authenticate realm is not an Azure Arc secret file" {

        AfterAll {
            $env:IDENTITY_ENDPOINT = $null
        }

        BeforeAll {
            $env:IDENTITY_ENDPOINT = $ArcEndpoint

            Mock -CommandName Test-Path -MockWith { return $false } -ParameterFilter { $LiteralPath -like '*ModuleSettings.clixml' }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
                $null -ne $HttpHeaders.Authorization
            } -MockWith { return @{ access_token = "mock-data" } }
        }

        It "should throw naming the path and the tokens directory, and never read '<Realm>'" -TestCases @(
            @{ Realm = 'C:\Windows\win.ini' }
            @{ Realm = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\..\..\..\Windows\win.ini' }
            @{ Realm = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\..\..\..\Windows\system.key' }
            @{ Realm = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\secret.txt' }
            @{ Realm = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\nested\secret.key' }
            @{ Realm = 'C:\ProgramData\AzureConnectedMachineAgent\secret.key' }
            @{ Realm = 'C:\Users\Public\AzureConnectedMachineAgent\Tokens\secret.key' }
            @{ Realm = '\\attacker\share\AzureConnectedMachineAgent\Tokens\secret.key' }
            @{ Realm = 'Tokens\secret.key' }
            @{ Realm = '/var/opt/azcmagent/tokens/secret.key' }
            @{ Realm = 'MOCKMOCKMOCKMOCKMOCKMOCK' }
        ) {
            param ($Realm)

            Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
                $null -eq $HttpHeaders.Authorization
            } -MockWith { Invoke-MockError -Realm $Realm }

            $expectedDirectory = '{0}\AzureConnectedMachineAgent\Tokens' -f $env:ProgramData

            { Get-AzManagedIdentityToken -OrganizationName "Contoso" } |
                Should -Throw "*$Realm*$expectedDirectory*"

            Assert-MockCalled -CommandName Get-Content -Times 0
            # Only the unauthenticated request was sent; nothing was retried with a credential.
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1
        }

        It "should throw when the realm is empty and never read a file" {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
                $null -eq $HttpHeaders.Authorization
            } -MockWith { Invoke-MockError -Realm '' }

            # An empty realm does not match the 'Basic realm=.+' challenge test and is reported as
            # the original error rather than as a secret-file problem; either way no file is read.
            { Get-AzManagedIdentityToken -OrganizationName "Contoso" } | Should -Throw

            Assert-MockCalled -CommandName Get-Content -Times 0
        }
    }

    Context "Linux Machines" {

        AfterAll {
            $env:IDENTITY_ENDPOINT = $null
        }

        BeforeAll {
            $env:IDENTITY_ENDPOINT = $ArcEndpoint

            Mock -CommandName Test-isWindowsAdmin -MockWith {
                return $false
            }
            Mock -CommandName Test-Path -MockWith { return $false } -ParameterFilter { $LiteralPath -like '*ModuleSettings.clixml' }
            Mock -CommandName Get-OperatingSystemInfo -MockWith { return @{ Windows = $false; Linux = $true; MacOS = $false } }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
                $null -eq $HttpHeaders.Authorization
            } -MockWith { Invoke-MockError -Realm $LinuxKeyFile }

            Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
                $null -ne $HttpHeaders.Authorization
            } -MockWith { return @{ access_token = "mock-data" } }
        }

        It "should not call Test-isWindowsAdmin" {
            Get-AzManagedIdentityToken -OrganizationName "Contoso"
            Assert-MockCalled -CommandName Test-isWindowsAdmin -Times 0
        }

        It "should read the secret file from the Linux tokens directory" {
            Get-AzManagedIdentityToken -OrganizationName "Contoso"
            Assert-MockCalled -CommandName Get-Content -ParameterFilter { $LiteralPath -eq $LinuxKeyFile }
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 2
        }

        It "should refuse a Windows-shaped realm on Linux and never read it" {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
                $null -eq $HttpHeaders.Authorization
            } -MockWith { Invoke-MockError -Realm $WindowsKeyFile }

            { Get-AzManagedIdentityToken -OrganizationName "Contoso" } |
                Should -Throw "*$WindowsKeyFile*/var/opt/azcmagent/tokens*"

            Assert-MockCalled -CommandName Get-Content -Times 0
        }

        It "should refuse a traversal out of the Linux tokens directory and never read it" {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
                $null -eq $HttpHeaders.Authorization
            } -MockWith { Invoke-MockError -Realm '/var/opt/azcmagent/tokens/../../../../etc/shadow' }

            { Get-AzManagedIdentityToken -OrganizationName "Contoso" } |
                Should -Throw "*/etc/shadow*/var/opt/azcmagent/tokens*"

            Assert-MockCalled -CommandName Get-Content -Times 0
        }
    }

    Context "When a valid cached managed identity token exists" {

        BeforeAll {
            $env:IDENTITY_ENDPOINT = $null

            $cachedPlainToken = 'cached-tökén-ünïcode'
            $cachedSettings = @{
                OrganizationName = 'Contoso'
                Token = [PSCustomObject]@{
                    tokenType    = 'ManagedIdentity'
                    access_token = (ConvertTo-SecureString -String $cachedPlainToken -AsPlainText -Force)
                    expires_on   = (Get-Date).AddHours(1)
                    expires_in   = 3600
                    resource     = '499b84ac-1321-427f-aa17-267ca6975798'
                    token_type   = 'Bearer'
                }
            }

            $script:originalCacheDirectory = $ENV:AZDODSC_CACHE_DIRECTORY
            $ENV:AZDODSC_CACHE_DIRECTORY = Join-Path -Path $TestDrive -ChildPath 'cache'

            Mock -CommandName Test-Path -MockWith { return $true } -ParameterFilter { $LiteralPath -like '*ModuleSettings.clixml' }
            Mock -CommandName Import-Clixml -MockWith { return $cachedSettings }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ access_token = "fresh-token" } }
        }

        AfterAll {
            $ENV:AZDODSC_CACHE_DIRECTORY = $script:originalCacheDirectory
        }

        It "should rebuild the token from the cache with the decoded SecureString and not call IMDS" {
            Get-AzManagedIdentityToken -OrganizationName "Contoso"

            Assert-MockCalled -CommandName New-ManagedIdentityToken -Times 1 -ParameterFilter {
                $ManagedIdentityTokenObj.access_token -ceq $cachedPlainToken
            }
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 0
        }
    }

    Context "When Verify switch is set" {

        BeforeAll {
            $env:IDENTITY_ENDPOINT = $null
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{
                    access_token = "fake-access-token"
                }
            }
        }

        It "should return managed identity token after verification" {
            $result = Get-AzManagedIdentityToken -OrganizationName "Contoso" -Verify
            $result.AccessToken | Should -Be "fake-access-token"
        }

        It "should throw error if Token verification fails" {
            Mock -CommandName Test-AzToken -MockWith {
                return $false
            } -ParameterFilter {
                $true
            }

            {
                Get-AzManagedIdentityToken -OrganizationName "Contoso" -Verify
            } | Should -Throw "Error. Failed to call the Azure DevOps API."
        }
    }

    Context "When access token is not returned from Azure Instance Metadata Service" {

        BeforeAll {
            $env:IDENTITY_ENDPOINT = $null
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                Throw "MOCK ERROR"
            }
            Mock -CommandName Test-Path -MockWith { return $false } -ParameterFilter { $LiteralPath -like '*ModuleSettings.clixml' }
        }

        It "should throw error" {
            {
                Get-AzManagedIdentityToken -OrganizationName "Contoso"
            } | Should -Throw
        }
    }

}
