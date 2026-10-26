@{
    # Script module or binary module file associated with this manifest.
    RootModule           = 'NlbDsc.psm1'

    # Version number of this module. This is controlled by gitversion.
    ModuleVersion        = '0.0.1'

    # ID used to uniquely identify this module
    GUID                 = 'c8a2f6e4-5d1b-4b8e-9a3f-7e2d1c0b4a96'

    # Author of this module
    Author               = 'Christoph Meyer'

    # Company or vendor of this module
    CompanyName          = 'NlbDsc contributors'

    # Copyright statement for this module
    Copyright            = 'Copyright the NlbDsc contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Module with DSC resources for the deployment and configuration of Windows Network Load Balancing (NLB) clusters.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '5.0'

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion           = '4.0'

    # Functions to export from this module
    FunctionsToExport    = @()

    # Cmdlets to export from this module
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module
    AliasesToExport      = @()

    # DSC resources to export from this module
    DscResourcesToExport = @(
        'NlbClusterDeployment'
        'NlbClusterNode'
        'NlbClusterNodeDip'
        'NlbClusterNodeState'
        'NlbClusterPortRule'
        'NlbClusterPortRuleNode'
        'NlbClusterState'
        'NlbClusterVip'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResource', 'NLB', 'NetworkLoadBalancing', 'LoadBalancing', 'WindowsServer')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.development.tega.intranetbw.de/ChristophMeyer/NlbDsc/blob/main/LICENSE'

            # Set to a prerelease string value if the release should be a prerelease.
            Prerelease   = ''

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.development.tega.intranetbw.de/ChristophMeyer/NlbDsc'

            # ReleaseNotes of this module
            ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}
