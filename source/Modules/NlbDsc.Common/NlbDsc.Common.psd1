@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'NlbDsc.Common.psm1'

    # Version number of this module.
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = '6f1f4c1d-3b0e-4d55-9f3a-0c5f6b2a8e71'

    # Author of this module
    Author            = 'Christoph Meyer'

    # Company or vendor of this module
    CompanyName       = 'NlbDsc contributors'

    # Copyright statement for this module
    Copyright         = 'Copyright the NlbDsc contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Functions used by the DSC resources in NlbDsc.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'ConvertFrom-NlbPortRule'
        'ConvertTo-NlbCmdletIPAddress'
        'ConvertTo-NlbDscValue'
        'ConvertTo-NlbNodeState'
        'ConvertTo-NlbPortRuleIPAddress'
        'Find-NlbClusterNode'
        'Find-NlbClusterPortRule'
        'Get-NlbDscCluster'
        'Get-NlbDscOsVersion'
        'Get-NlbObjectPropertyValue'
        'Get-NlbShortName'
        'Import-NlbModule'
        'Install-NlbFeature'
        'Test-NlbDscOsRequirement'
        'Test-NlbFeatureInstalled'
        'Test-NlbIPAddressEqual'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
        PSData = @{
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
