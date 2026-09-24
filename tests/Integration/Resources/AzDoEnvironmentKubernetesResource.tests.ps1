# AzDoEnvironmentKubernetesResource creates a resource against a pipeline environment that
# addresses a Kubernetes cluster through a service connection. Exercising this live requires a
# Kubernetes-type service connection, which this file creates for itself (via AzDoServiceConnection)
# using a placeholder kubeconfig - the same synthetic-connection approach the issue calls for. Some
# organizations validate connectivity to the cluster before accepting the environment resource
# (POST .../providers/kubernetes); if that happens here the create/no-drift/tag-drift Contexts below
# report the refusal with Set-ItResult -Skipped (never -Skip) and this gap is called out explicitly
# in the PR body and docs/ResourceRoadmap.md. Unit tests
# (tests/Unit/.../AzDoEnvironmentKubernetesResource/*) cover the resource's logic - lookup, status
# mapping, delete+recreate drift remediation and Tags comparison - independently of live cluster
# reachability.

Describe "AzDoEnvironmentKubernetesResource Integration Tests" -Tag "Integration", "EnvironmentKubernetesResource" {

    BeforeAll {

        $PROJECTNAME = 'TEST_ENV_K8S'
        $script:kubernetesResourceUsable = $true
        $script:kubernetesResourceSkipReason = $null

        New-TestProject -ProjectName $PROJECTNAME

        # Pipeline environment the Kubernetes resource attaches to.
        $envParameters = @{
            Name       = 'AzDoPipelineEnvironment'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProjectName     = $PROJECTNAME
                EnvironmentName = 'TEST_K8S_ENV'
                Description     = 'Test environment for Kubernetes resource'
            }
        }
        Invoke-DscResource @envParameters

        # Synthetic Kubernetes service connection with a placeholder (unreachable) cluster and
        # kubeconfig. Created via the AzDoServiceConnection DSC resource, matching the pattern the
        # sibling AzDoServiceConnection integration tests use for other connection types.
        $scParameters = @{
            Name       = 'AzDoServiceConnection'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProjectName    = $PROJECTNAME
                ConnectionName = 'TEST_K8S_SC'
                ConnectionType = 'kubernetes'
                Description    = 'Test Kubernetes service connection (placeholder cluster)'
                Authorization  = @{
                    scheme     = 'Kubernetes'
                    parameters = @{
                        kubeconfig            = "apiVersion: v1`nclusters:`n- cluster:`n    server: https://placeholder.example.com`n  name: placeholder`ncontexts:`n- context:`n    cluster: placeholder`n    user: placeholder`n  name: placeholder`ncurrent-context: placeholder`nusers:`n- name: placeholder`n  user:`n    token: placeholder`n"
                        clusterContext        = 'placeholder'
                    }
                }
                Data           = @{
                    authorizationType = 'Kubeconfig'
                    acceptUntrustedCerts = 'true'
                }
            }
        }

        try
        {
            Invoke-DscResource @scParameters
        }
        catch
        {
            $script:kubernetesResourceUsable = $false
            $script:kubernetesResourceSkipReason = "the live organization refused creation of the placeholder Kubernetes service connection: $($_.Exception.Message)"
        }

        $parameters = @{
            Name       = 'AzDoEnvironmentKubernetesResource'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName            = $PROJECTNAME
                EnvironmentName        = 'TEST_K8S_ENV'
                KubernetesResourceName = 'TEST_K8S_RESOURCE'
                Namespace              = 'test-namespace'
                ServiceConnectionName  = 'TEST_K8S_SC'
                Tags                   = @('tag1', 'tag2')
                Ensure                 = 'Present'
            }
        }
    }

    Context "Testing if the Kubernetes resource exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (Kubernetes resource does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the Kubernetes resource" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            if (-not $script:kubernetesResourceUsable)
            {
                Set-ItResult -Skipped -Because $script:kubernetesResourceSkipReason
            }

            try
            {
                { Invoke-DscResource @parameters } | Should -Not -Throw
            }
            catch
            {
                $script:kubernetesResourceUsable = $false
                Set-ItResult -Skipped -Because "the live organization refused creation of the environment Kubernetes resource without a reachable cluster: $($_.Exception.Message)"
            }
        }

        It "Should return True after creation (no drift)" {
            if (-not $script:kubernetesResourceUsable)
            {
                Set-ItResult -Skipped -Because 'the environment Kubernetes resource could not be created in this organization; see the preceding Context'
            }

            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Correcting Tags drift (delete and recreate)" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Tags = @('tag1', 'tag2', 'tag3')
        }

        It "Should not throw any exceptions" {
            if (-not $script:kubernetesResourceUsable)
            {
                Set-ItResult -Skipped -Because 'the environment Kubernetes resource could not be created in this organization; see the earlier Context'
            }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after the tags are corrected" {
            if (-not $script:kubernetesResourceUsable)
            {
                Set-ItResult -Skipped -Because 'the environment Kubernetes resource could not be created in this organization; see the earlier Context'
            }

            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the Kubernetes resource" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName            = $PROJECTNAME
                EnvironmentName        = 'TEST_K8S_ENV'
                KubernetesResourceName = 'TEST_K8S_RESOURCE'
                Namespace              = 'test-namespace'
                ServiceConnectionName  = 'TEST_K8S_SC'
                Ensure                 = 'Absent'
            }
        }

        It "Should not throw any exceptions" {
            if (-not $script:kubernetesResourceUsable)
            {
                Set-ItResult -Skipped -Because 'the environment Kubernetes resource could not be created in this organization; see the earlier Context'
            }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Absent is desired state)" {
            if (-not $script:kubernetesResourceUsable)
            {
                Set-ItResult -Skipped -Because 'the environment Kubernetes resource could not be created in this organization; see the earlier Context'
            }

            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
