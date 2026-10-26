# Localized resources for NlbDsc.Common

ConvertFrom-StringData @'
    FeatureCmdletNotAvailable = The command 'Get-WindowsFeature' is not available. Network Load Balancing can only be managed on Windows Server. (NLBC0001)
    FeatureNotInstalled = The Windows feature '{0}' is not installed. (NLBC0002)
    FeatureInstalled = The Windows features required for Network Load Balancing are installed. (NLBC0003)
    InstallingFeature = Installing the Windows features '{0}'. (NLBC0004)
    InstallFeatureFailed = Failed to install the Windows features '{0}'. Exit code '{1}'. (NLBC0005)
    InstallFeatureRestartRequired = The installation of the Windows features '{0}' requires a restart of the node. (NLBC0006)
    ModuleNotAvailable = The PowerShell module 'NetworkLoadBalancingClusters' is not available. Make sure the Windows features 'NLB' and 'RSAT-NLB' are installed. (NLBC0007)
    ImportingModule = Importing the PowerShell module 'NetworkLoadBalancingClusters' into the global scope. (NLBC0008)
    ClusterQueryFailed = Could not query an NLB cluster on interface '{0}' of host '{1}'. {2} (NLBC0009)
    ClusterNotFound = No NLB cluster is bound to interface '{0}' of host '{1}'. (NLBC0010)
'@
