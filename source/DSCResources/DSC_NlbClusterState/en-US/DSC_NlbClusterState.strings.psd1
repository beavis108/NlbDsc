# Localized resources for DSC_NlbClusterState

ConvertFrom-StringData @'
    GetCurrentState = Getting the host state of all nodes of the NLB cluster on interface '{0}'. (NLBCS0001)
    FeatureNotInstalled = The Windows features for Network Load Balancing are not installed. (NLBCS0002)
    ClusterNotFound = No NLB cluster is bound to interface '{0}' of host '{1}'. (NLBCS0003)
    NodeStates = The nodes of the NLB cluster have the states '{0}'. (NLBCS0004)
    TestDesiredState = Determining whether all nodes of the NLB cluster have the host state '{0}'. (NLBCS0005)
    InDesiredState = All nodes of the NLB cluster have the host state '{0}'. (NLBCS0006)
    NotInDesiredState = Not all nodes of the NLB cluster have the host state '{0}' ('{1}'). (NLBCS0007)
    ClusterRequired = No NLB cluster is bound to interface '{0}' of host '{1}'. (NLBCS0008)
    ResumingCluster = Resuming all nodes of the NLB cluster '{0}'. (NLBCS0009)
    StartingCluster = Starting all nodes of the NLB cluster '{0}'. (NLBCS0010)
    StoppingCluster = Stopping all nodes of the NLB cluster '{0}' (drain: '{1}'). (NLBCS0011)
    SuspendingCluster = Suspending all nodes of the NLB cluster '{0}'. (NLBCS0012)
    ChangeStateFailed = Failed to change the host state of the NLB cluster '{0}' to '{1}'. (NLBCS0013)
'@
