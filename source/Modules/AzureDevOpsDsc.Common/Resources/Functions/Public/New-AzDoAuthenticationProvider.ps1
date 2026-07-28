<#
.SYNOPSIS
Creates a new Azure DevOps authentication provider.

.DESCRIPTION
The New-AzDoAuthenticationProvider function configures authentication for Azure DevOps DSC.
It supports multiple authentication methods: Personal Access Token, Managed Identity,
Service Principal with Client Secret, Service Principal with Certificate, Azure CLI, and
Workload Identity Federation (file-based, GitHub Actions OIDC, or a manually-supplied token).

.PARAMETER OrganizationName
Specifies the name of the Azure DevOps organization.

.EXAMPLE
New-AzDoAuthenticationProvider -OrganizationName "Contoso" -PersonalAccessToken "myPAT"

.EXAMPLE
New-AzDoAuthenticationProvider -OrganizationName "Contoso" -useManagedIdentity

.EXAMPLE
New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "..." -ClientId "..." -ClientSecret "..."

.EXAMPLE
New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "..." -ClientId "..." -CertificateThumbprint "..."

.EXAMPLE
New-AzDoAuthenticationProvider -OrganizationName "Contoso" -useAzureCLI

.EXAMPLE
New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "..." -ClientId "..." -FederatedTokenFile "/var/run/secrets/azure/tokens/azure-identity-token"

.EXAMPLE
New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "..." -ClientId "..." -useGitHubActionsOIDC

.EXAMPLE
New-AzDoAuthenticationProvider -OrganizationName "Contoso" -TenantId "..." -ClientId "..." -FederatedToken $secureJwt
#>
Function New-AzDoAuthenticationProvider
{
    [CmdletBinding(DefaultParameterSetName = 'PersonalAccessToken')]
    param (
        # Organization Name
        [Parameter(Mandatory = $true, ParameterSetName = 'PersonalAccessToken')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SecureStringPersonalAccessToken')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ManagedIdentity')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePrincipal')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SecureStringServicePrincipal')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CertificateFile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AzureCLI')]
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkloadIdentityFederationFile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkloadIdentityFederationGitHubActions')]
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkloadIdentityFederationToken')]
        [Alias('OrgName')]
        [String]
        $OrganizationName,

        # Personal Access Token
        [Parameter(Mandatory = $true, ParameterSetName = 'PersonalAccessToken')]
        [Alias('PAT')]
        [String]
        $PersonalAccessToken,

        # SecureString Personal Access Token
        [Parameter(Mandatory = $true, ParameterSetName = 'SecureStringPersonalAccessToken')]
        [Alias('SecureStringPAT')]
        [SecureString]
        $SecureStringPersonalAccessToken,

        # Use Managed Identity
        [Parameter(ParameterSetName = 'ManagedIdentity')]
        [Switch]
        $useManagedIdentity,

        # Service Principal parameters
        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePrincipal')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SecureStringServicePrincipal')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CertificateFile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkloadIdentityFederationFile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkloadIdentityFederationGitHubActions')]
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkloadIdentityFederationToken')]
        [String]
        $TenantId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePrincipal')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SecureStringServicePrincipal')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CertificateFile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkloadIdentityFederationFile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkloadIdentityFederationGitHubActions')]
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkloadIdentityFederationToken')]
        [String]
        $ClientId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePrincipal')]
        [String]
        $ClientSecret,

        [Parameter(Mandatory = $true, ParameterSetName = 'SecureStringServicePrincipal')]
        [SecureString]
        $SecureStringClientSecret,

        # Certificate parameters (Windows cert store thumbprint)
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [String]
        $CertificateThumbprint,

        # Certificate parameters (PFX file, cross-platform)
        [Parameter(Mandatory = $true, ParameterSetName = 'CertificateFile')]
        [String]
        $CertificatePath,

        [Parameter(Mandatory = $true, ParameterSetName = 'CertificateFile')]
        [SecureString]
        $CertificatePassword,

        # Use Azure CLI credentials
        [Parameter(ParameterSetName = 'AzureCLI')]
        [Switch]
        $useAzureCLI,

        # Workload Identity Federation - file-based federated token (e.g. AKS/Kubernetes workload identity)
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkloadIdentityFederationFile')]
        [String]
        $FederatedTokenFile,

        # Workload Identity Federation - acquire the federated token from GitHub Actions' OIDC endpoint
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkloadIdentityFederationGitHubActions')]
        [Switch]
        $useGitHubActionsOIDC,

        [Parameter(ParameterSetName = 'WorkloadIdentityFederationGitHubActions')]
        [String]
        $GitHubActionsAudience = 'api://AzureADTokenExchange',

        # Workload Identity Federation - a federated token already obtained by the caller
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkloadIdentityFederationToken')]
        [SecureString]
        $FederatedToken,

        # Don't verify the Token
        [Parameter(ParameterSetName = 'ManagedIdentity')]
        [Parameter(ParameterSetName = 'PersonalAccessToken')]
        [Parameter(ParameterSetName = 'ServicePrincipal')]
        [Parameter(ParameterSetName = 'SecureStringServicePrincipal')]
        [Parameter(ParameterSetName = 'Certificate')]
        [Parameter(ParameterSetName = 'CertificateFile')]
        [Parameter(ParameterSetName = 'AzureCLI')]
        [Parameter(ParameterSetName = 'WorkloadIdentityFederationFile')]
        [Parameter(ParameterSetName = 'WorkloadIdentityFederationGitHubActions')]
        [Parameter(ParameterSetName = 'WorkloadIdentityFederationToken')]
        [Switch]
        $NoVerify,

        # Do not export the Token (used by DSC resources that inherit from base class)
        [Parameter(ParameterSetName = 'PersonalAccessToken')]
        [Parameter(ParameterSetName = 'SecureStringPersonalAccessToken')]
        [Parameter(ParameterSetName = 'ManagedIdentity')]
        [Parameter(ParameterSetName = 'ServicePrincipal')]
        [Parameter(ParameterSetName = 'SecureStringServicePrincipal')]
        [Parameter(ParameterSetName = 'Certificate')]
        [Parameter(ParameterSetName = 'CertificateFile')]
        [Parameter(ParameterSetName = 'AzureCLI')]
        [Parameter(ParameterSetName = 'WorkloadIdentityFederationFile')]
        [Parameter(ParameterSetName = 'WorkloadIdentityFederationGitHubActions')]
        [Parameter(ParameterSetName = 'WorkloadIdentityFederationToken')]
        [Switch]
        $isResource

    )

    # Test if $ENV:AZDODSC_CACHE_DIRECTORY is set. If not, throw an error.
    if ($null -eq $ENV:AZDODSC_CACHE_DIRECTORY)
    {
        Throw "[New-AzDoAuthenticationProvider] The Environment Variable 'AZDODSC_CACHE_DIRECTORY' is not set. Please set the Environment Variable 'AZDODSC_CACHE_DIRECTORY' to the Cache Directory."
    }

    # Set the Global Variables
    $Global:DSCAZDO_OrganizationName = $OrganizationName
    $Global:DSCAZDO_AuthenticationToken = $null

    #
    # If the parameterset is PersonalAccessToken
    if ($PSCmdlet.ParameterSetName -eq 'PersonalAccessToken')
    {

        Write-Verbose "[New-AzDoAuthenticationProvider] Creating a new Personal Access Token with OrganizationName $OrganizationName."

        # if the NoVerify switch is not set, verify the Token.
        if ($NoVerify)
        {
            $Global:DSCAZDO_AuthenticationToken = Set-AzPersonalAccessToken -PersonalAccessToken $PersonalAccessToken -OrganizationName $OrganizationName
        }
        else
        {
            $Global:DSCAZDO_AuthenticationToken = Set-AzPersonalAccessToken -PersonalAccessToken $PersonalAccessToken -Verify -OrganizationName $OrganizationName
        }

    }
    # If the parameterset is ManagedIdentity
    elseif ($PSCmdlet.ParameterSetName -eq 'ManagedIdentity')
    {

        Write-Verbose "[New-AzDoAuthenticationProvider] Creating a new Azure Managed Identity with OrganizationName $OrganizationName."

        if ($NoVerify)
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzManagedIdentityToken -OrganizationName $OrganizationName
        }
        else
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzManagedIdentityToken -OrganizationName $OrganizationName -Verify
        }

    }
    # If the parameterset is SecureStringPersonalAccessToken
    elseif ($PSCmdlet.ParameterSetName -eq 'SecureStringPersonalAccessToken')
    {
        Write-Verbose "[New-AzDoAuthenticationProvider] Creating a new Personal Access Token with OrganizationName $OrganizationName."
        $Global:DSCAZDO_AuthenticationToken = Set-AzPersonalAccessToken -SecureStringPersonalAccessToken $SecureStringPersonalAccessToken -OrganizationName $OrganizationName
    }
    # If the parameterset is ServicePrincipal
    elseif ($PSCmdlet.ParameterSetName -eq 'ServicePrincipal')
    {
        Write-Verbose "[New-AzDoAuthenticationProvider] Creating a Service Principal token with OrganizationName $OrganizationName."

        if ($NoVerify)
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzServicePrincipalToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
        }
        else
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzServicePrincipalToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret -Verify
        }
    }
    # If the parameterset is SecureStringServicePrincipal
    elseif ($PSCmdlet.ParameterSetName -eq 'SecureStringServicePrincipal')
    {
        Write-Verbose "[New-AzDoAuthenticationProvider] Creating a Service Principal token (SecureString) with OrganizationName $OrganizationName."

        if ($NoVerify)
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzServicePrincipalToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -SecureStringClientSecret $SecureStringClientSecret
        }
        else
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzServicePrincipalToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -SecureStringClientSecret $SecureStringClientSecret -Verify
        }
    }
    # If the parameterset is Certificate (thumbprint)
    elseif ($PSCmdlet.ParameterSetName -eq 'Certificate')
    {
        Write-Verbose "[New-AzDoAuthenticationProvider] Creating a Certificate token (thumbprint) with OrganizationName $OrganizationName."

        if ($NoVerify)
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzServicePrincipalCertificateToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint
        }
        else
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzServicePrincipalCertificateToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -Verify
        }
    }
    # If the parameterset is CertificateFile (PFX path)
    elseif ($PSCmdlet.ParameterSetName -eq 'CertificateFile')
    {
        Write-Verbose "[New-AzDoAuthenticationProvider] Creating a Certificate token (PFX file) with OrganizationName $OrganizationName."

        if ($NoVerify)
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzServicePrincipalCertificateToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -CertificatePath $CertificatePath -CertificatePassword $CertificatePassword
        }
        else
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzServicePrincipalCertificateToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -CertificatePath $CertificatePath -CertificatePassword $CertificatePassword -Verify
        }
    }
    # If the parameterset is AzureCLI
    elseif ($PSCmdlet.ParameterSetName -eq 'AzureCLI')
    {
        Write-Verbose "[New-AzDoAuthenticationProvider] Creating an Azure CLI token with OrganizationName $OrganizationName."

        if ($NoVerify)
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzCliToken -OrganizationName $OrganizationName
        }
        else
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzCliToken -OrganizationName $OrganizationName -Verify
        }
    }
    # If the parameterset is WorkloadIdentityFederationFile
    elseif ($PSCmdlet.ParameterSetName -eq 'WorkloadIdentityFederationFile')
    {
        Write-Verbose "[New-AzDoAuthenticationProvider] Creating a Workload Identity Federation token (file) with OrganizationName $OrganizationName."

        if ($NoVerify)
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzWorkloadIdentityFederationToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -FederatedTokenFile $FederatedTokenFile
        }
        else
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzWorkloadIdentityFederationToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -FederatedTokenFile $FederatedTokenFile -Verify
        }
    }
    # If the parameterset is WorkloadIdentityFederationGitHubActions
    elseif ($PSCmdlet.ParameterSetName -eq 'WorkloadIdentityFederationGitHubActions')
    {
        Write-Verbose "[New-AzDoAuthenticationProvider] Creating a Workload Identity Federation token (GitHub Actions OIDC) with OrganizationName $OrganizationName."

        if ($NoVerify)
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzWorkloadIdentityFederationToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -GitHubActions -GitHubActionsAudience $GitHubActionsAudience
        }
        else
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzWorkloadIdentityFederationToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -GitHubActions -GitHubActionsAudience $GitHubActionsAudience -Verify
        }
    }
    # If the parameterset is WorkloadIdentityFederationToken
    elseif ($PSCmdlet.ParameterSetName -eq 'WorkloadIdentityFederationToken')
    {
        Write-Verbose "[New-AzDoAuthenticationProvider] Creating a Workload Identity Federation token (manually-supplied) with OrganizationName $OrganizationName."

        $BSTR                = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($FederatedToken)
        $plainFederatedToken = if ($isLinux) {
            [System.Runtime.InteropServices.Marshal]::PtrToStringUni($BSTR)
        } else {
            [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        }
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        if ($NoVerify)
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzWorkloadIdentityFederationToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -FederatedToken $plainFederatedToken
        }
        else
        {
            $Global:DSCAZDO_AuthenticationToken = Get-AzWorkloadIdentityFederationToken -OrganizationName $OrganizationName -TenantId $TenantId -ClientId $ClientId -FederatedToken $plainFederatedToken -Verify
        }
    }

    # Export the Token information to the Cache Directory
    if ($isResource.IsPresent)
    {
        Write-Verbose "[New-AzDoAuthenticationProvider] isResource is set. The Token will not be exported."
        return
    }


    # Initialize the Cache
    Get-AzDoCacheObjects | ForEach-Object {
        Initialize-CacheObject -CacheType $_
    }

    # Iterate through Each of the Caching Commands and initalize the Cache.
    Get-Command "AzDoAPI_*" | Where-Object Source -eq 'AzureDevOpsDsc.Common' | ForEach-Object {
        . $_.Name -OrganizationName $AzureDevopsOrganizationName
    }

    # Export the Token to the Cache Directory

    # Create an Object Containing the Organization Name.
    $moduleSettingsPath = Join-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY -ChildPath "ModuleSettings.clixml"
    Write-Verbose "[New-AzDoAuthenticationProvider] Exporting the Module Settings to $moduleSettingsPath."

    $objectSettings = [PSCustomObject]@{
        OrganizationName = (Get-AzDoOrganizationName)
        Token = $Global:DSCAZDO_AuthenticationToken
        SecurityDescriptorTypes = Join-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY -ChildPath "SecurityDescriptors.clixml"
    }

    # Export the Object to the Cache Directory
    $objectSettings | Export-Clixml -LiteralPath $moduleSettingsPath -Depth 5

}
