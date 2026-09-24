Describe "AzDoApiUri Integration Tests" -Tag "Integration", "ApiUri" {

    # Not a DSC resource: exercises Get-AzDoApiUri directly against every Services
    # value, confirming the base URL it resolves is one the live organization actually
    # answers on. Read-only throughout - nothing is created or modified.

    BeforeAll {

        $ORG = Resolve-TestOrg
        $hdr = Resolve-TestAuthHeader

        # Get-AzDoApiUri is private to AzureDevOpsDsc.Common - it is not exported, so the test
        # session cannot call it by name. Invoke it inside the module's own scope instead.
        $commonModule = Get-Module -Name 'AzureDevOpsDsc.Common' | Select-Object -First 1
        if ($null -eq $commonModule)
        {
            throw "AzureDevOpsDsc.Common is not loaded; the test framework initialization should have imported it."
        }

        function Get-TestApiUri
        {
            param([string]$Service, [string]$OrganizationName)
            & $commonModule { param($s, $o) Get-AzDoApiUri -Service $s -OrganizationName $o } $Service $OrganizationName
        }

        $script:FirstProjectName = $null
    }

    Context "Core" {

        It "resolves a base URL that answers a project list read" {
            $base = Get-TestApiUri -Service Core -OrganizationName $ORG

            $base | Should -BeExactly "https://dev.azure.com/$ORG"

            $response = Invoke-RestMethod -Headers $hdr -Method Get -Uri "$base/_apis/projects?`$top=1&api-version=7.1"

            $response.count | Should -BeGreaterOrEqual 0
            if ($response.value.Count -gt 0)
            {
                $script:FirstProjectName = $response.value[0].name
            }
        }
    }

    Context "Identity" {

        It "resolves a base URL that answers a graph groups read" {
            $base = Get-TestApiUri -Service Identity -OrganizationName $ORG

            $base | Should -BeExactly "https://vssps.dev.azure.com/$ORG"

            { Invoke-RestMethod -Headers $hdr -Method Get -Uri "$base/_apis/graph/groups?api-version=7.1-preview.1" } | Should -Not -Throw
        }
    }

    Context "Entitlements" {

        It "resolves a base URL that answers a user entitlements read" {
            $base = Get-TestApiUri -Service Entitlements -OrganizationName $ORG

            $base | Should -BeExactly "https://vsaex.dev.azure.com/$ORG"

            { Invoke-RestMethod -Headers $hdr -Method Get -Uri "$base/_apis/userentitlements?`$top=1&api-version=7.1-preview.4" } | Should -Not -Throw
        }
    }

    Context "Feeds" {

        It "resolves a base URL that answers a feeds list read" {
            $base = Get-TestApiUri -Service Feeds -OrganizationName $ORG

            $base | Should -BeExactly "https://feeds.dev.azure.com/$ORG"

            { Invoke-RestMethod -Headers $hdr -Method Get -Uri "$base/_apis/packaging/feeds?api-version=7.1" } | Should -Not -Throw
        }
    }

    Context "Audit" {

        It "resolves a base URL that answers an audit log read, or is skipped when the run identity lacks audit read" {
            $base = Get-TestApiUri -Service Audit -OrganizationName $ORG

            $base | Should -BeExactly "https://auditservice.dev.azure.com/$ORG"

            try
            {
                Invoke-RestMethod -Headers $hdr -Method Get -Uri "$base/_apis/audit/auditlog?batchSize=1&api-version=7.1-preview.1" | Out-Null
            }
            catch
            {
                $statusCode = $_.Exception.Response.StatusCode.value__

                if ($statusCode -eq 401 -or $statusCode -eq 403)
                {
                    Set-ItResult -Skipped -Because "the run identity does not have audit log read permission on this organization"
                }
                else
                {
                    throw
                }
            }
        }
    }

    Context "Release" {

        It "resolves a base URL that answers a project-scoped release definitions read" {
            $base = Get-TestApiUri -Service Release -OrganizationName $ORG

            $base | Should -BeExactly "https://vsrm.dev.azure.com/$ORG"

            if (-not $script:FirstProjectName)
            {
                Set-ItResult -Skipped -Because "no project was available from the Core probe to scope the release definitions read to"
                return
            }

            { Invoke-RestMethod -Headers $hdr -Method Get -Uri "$base/$script:FirstProjectName/_apis/release/definitions?`$top=1&api-version=7.1" } | Should -Not -Throw
        }
    }
}
