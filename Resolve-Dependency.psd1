@{
    Gallery                                    = 'PSGallery'
    AllowPrerelease                            = $false
    WithYAML                                   = $true # Will also bootstrap PowerShell-Yaml to read other config files

    #UseModuleFast = $true
    #ModuleFastVersion = '0.1.2'
    #ModuleFastBleedingEdge = $true

    UsePSResourceGet                           = $true
    # Pinned. Left unset, the bootstrap downloads the newest PSResourceGet on every run, and
    # 1.3.1 fails the first Save-PSResource with 'Response returned status code package: Not
    # Found.' 1.2.0 is the version the last passing build used.
    PSResourceGetVersion                       = '1.2.0'

    UsePowerShellGetCompatibilityModule        = $true
    UsePowerShellGetCompatibilityModuleVersion = '3.0.23-beta23'
}
