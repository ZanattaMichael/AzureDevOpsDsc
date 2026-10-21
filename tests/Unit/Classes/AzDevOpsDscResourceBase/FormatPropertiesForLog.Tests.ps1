using module AzureDevOpsDscNative

Describe "[AzDevOpsDscResourceBase]::FormatPropertiesForLog() Tests" -Tag "Unit", "AzDevOpsDscResourceBase" {

    Context 'When the resource declares a secret DscProperty' {

        class FormatPropertiesForLogExampleSecret : AzDevOpsDscResourceBase
        {
            [DscProperty(Key)]
            [string]$Name

            [DscProperty()]
            [HashTable]$Authorization

            [string]GetResourceName()
            {
                return 'FormatPropertiesForLogExampleSecret'
            }

            hidden [System.String[]]GetDscResourceSecretPropertyNames()
            {
                return @('Authorization')
            }
        }

        BeforeAll {
            $properties = @{
                Name          = 'One'
                Ensure        = [Ensure]::Present
                Authorization = @{ scheme = 'ServicePrincipal'; serviceprincipalkey = 'the-real-secret-value' }
                Variables     = @{ APP_KEY = @{ value = 'the-variable-secret'; isSecret = $true }; APP_ENV = 'prod' }
                LookupResult  = @{ status = 'Unchanged'; liveCache = [PSCustomObject]@{ token = 'the-live-secret' } }
                Shared        = @('A', 'B')
                Nothing       = $null
            }
            $rendered = [FormatPropertiesForLogExampleSecret]::new().FormatPropertiesForLog($properties)
        }

        It 'Should redact the secret property' {
            $rendered | Should -Match '(?m)^  Authorization = <redacted>\r?$'
        }

        It 'Should never contain a secret value, whether named secret, nested in a hashtable or in LookupResult' {
            $rendered | Should -Not -Match 'the-real-secret-value'
            $rendered | Should -Not -Match 'the-variable-secret'
            $rendered | Should -Not -Match 'the-live-secret'
            $rendered | Should -Not -Match 'serviceprincipalkey'
        }

        It 'Should show a hashtable-valued property as its key names only' {
            $rendered | Should -Match '(?m)^  Variables = \{APP_ENV, APP_KEY\}\r?$'
            $rendered | Should -Match '(?m)^  LookupResult = \{liveCache, status\}\r?$'
            $rendered | Should -Not -Match 'prod'
            $rendered | Should -Not -Match 'Unchanged'
        }

        It 'Should show scalar and list values as strings' {
            $rendered | Should -Match '(?m)^  Name = One\r?$'
            $rendered | Should -Match '(?m)^  Ensure = Present\r?$'
            $rendered | Should -Match '(?m)^  Shared = \[A, B\]\r?$'
            $rendered | Should -Match '(?m)^  Nothing = \r?$'
        }

        It 'Should render one line per property' {
            @($rendered -split "`r?`n").Count | Should -Be $properties.Count
        }
    }

    Context 'When the resource declares no secret DscProperty' {

        class FormatPropertiesForLogExamplePlain : AzDevOpsDscResourceBase
        {
            [DscProperty(Key)]
            [string]$Name

            [string]GetResourceName()
            {
                return 'FormatPropertiesForLogExamplePlain'
            }
        }

        It 'Should still show a hashtable as key names only' {
            $rendered = [FormatPropertiesForLogExamplePlain]::new().FormatPropertiesForLog(@{ Inputs = @{ url = 'https://x'; password = 'the-real-secret-value' } })
            $rendered | Should -Be '  Inputs = {password, url}'
        }

        It 'Should return an empty string for null or empty input' {
            [FormatPropertiesForLogExamplePlain]::new().FormatPropertiesForLog($null) | Should -Be ''
            [FormatPropertiesForLogExamplePlain]::new().FormatPropertiesForLog(@{}) | Should -Be ''
        }
    }
}
