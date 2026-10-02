Describe "AzDoProject Integration Tests - Inherited Process" -Tag "Integration", "Project" {

    BeforeAll {

        # Auth helper for direct REST verification (see CLAUDE.md "Auth Helper Pattern for
        # Integration Tests") - Invoke-AzDevOpsApiRestMethod/Add-AuthenticationHTTPHeader are not
        # available in this test scope.
        function New-RestAuthHeader {
            $cfg  = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
            $tok  = $cfg.Token
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($tok.access_token)
            try   { $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
            finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
            if ($tok.tokenType.ToString() -eq 'PersonalAccessToken' -or $tok.tokenType.ToString() -eq '1') {
                $encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$plain"))
                return @{ Authorization = "Basic $encoded" }
            } else {
                return @{ Authorization = "Bearer $plain" }
            }
        }

        $settings = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
        $ORG      = $settings.OrganizationName

        # Inherited processes and project names cannot be reused while a prior run's namesake is
        # still being torn down - use a unique suffix per run.
        $suffix = Get-Random -Maximum 99999
        $PROCESSNAME_A = "ITProjProcA$suffix"
        $PROCESSNAME_B = "ITProjProcB$suffix"
        $PROJECTNAME   = "ITINHERITEDPROJ$suffix"

        # Two inherited processes from the same system parent ('Agile') - the project is created on
        # the first and later migrated to the second, exercising the "two inheritors of the same
        # parent" compatible-migration path.
        $processParametersA = @{
            Name       = 'AzDoProcess'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProcessName       = $PROCESSNAME_A
                ParentProcessName = 'Agile'
                Description       = 'Inherited process A for AzDoProject integration testing'
            }
        }
        $processParametersB = @{
            Name       = 'AzDoProcess'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProcessName       = $PROCESSNAME_B
                ParentProcessName = 'Agile'
                Description       = 'Inherited process B for AzDoProject integration testing'
            }
        }

        Invoke-DscResource @processParametersA
        Invoke-DscResource @processParametersB
        Start-Sleep -Seconds 5

        $parameters = @{
            Name       = 'AzDoProject'
            ModuleName = 'AzureDevOpsDscNative'
        }

        function Get-ITProjectCapabilities {
            $header = New-RestAuthHeader
            Invoke-RestMethod -Uri "https://dev.azure.com/$ORG/_apis/projects/${PROJECTNAME}?includeCapabilities=true&api-version=7.1" -Headers $header -Method Get
        }
    }

    AfterAll {
        # Best-effort cleanup - failures here should not fail the run, just leave stragglers for
        # the framework's pre-run teardown to catch on the next execution.
        try {
            Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDscNative' -Method 'Set' -Property @{ ProjectName = $PROJECTNAME; Ensure = 'Absent' }
        } catch { Write-Warning "[AzDoProject.InheritedProcess] Project cleanup failed: $_" }

        try {
            Invoke-DscResource -Name 'AzDoProcess' -ModuleName 'AzureDevOpsDscNative' -Method 'Set' -Property @{ ProcessName = $PROCESSNAME_A; ParentProcessName = 'Agile'; Ensure = 'Absent' }
        } catch { Write-Warning "[AzDoProject.InheritedProcess] Process A cleanup failed: $_" }

        try {
            Invoke-DscResource -Name 'AzDoProcess' -ModuleName 'AzureDevOpsDscNative' -Method 'Set' -Property @{ ProcessName = $PROCESSNAME_B; ParentProcessName = 'Agile'; Ensure = 'Absent' }
        } catch { Write-Warning "[AzDoProject.InheritedProcess] Process B cleanup failed: $_" }
    }

    Context "Creating a project on an inherited process" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName     = $PROJECTNAME
                ProcessTemplate = $PROCESSNAME_A
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should report InDesiredState True once created" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should report the inherited process via the REST API" {
            $capabilities = Get-ITProjectCapabilities
            $capabilities.capabilities.processTemplate.templateName | Should -Be $PROCESSNAME_A
        }
    }

    Context "Migrating the project to a sibling inherited process" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName     = $PROJECTNAME
                ProcessTemplate = $PROCESSNAME_B
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should report InDesiredState True after the migration" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should report the sibling process via the REST API" {
            $capabilities = Get-ITProjectCapabilities
            $capabilities.capabilities.processTemplate.templateName | Should -Be $PROCESSNAME_B
        }
    }

    Context "Refusing to migrate to an unrelated process family" {

        BeforeAll {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName     = $PROJECTNAME
                ProcessTemplate = 'Scrum'
            }
        }

        It "Should not throw, and should report drift rather than silently applying it" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }

        It "Should leave the project on its current process" {
            $capabilities = Get-ITProjectCapabilities
            $capabilities.capabilities.processTemplate.templateName | Should -Be $PROCESSNAME_B
        }
    }

    Context "Removing the project" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                Ensure      = 'Absent'
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should report InDesiredState True after removal" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
