# Localized resources for DSC_NlbClusterVip

ConvertFrom-StringData @'
    GetCurrentState = Getting the virtual IP address '{0}' of the NLB cluster on interface '{1}'. (NLBVIP0001)
    FeatureNotInstalled = The Windows features for Network Load Balancing are not installed. The virtual IP address is reported as absent. (NLBVIP0002)
    ClusterNotFound = No NLB cluster is bound to interface '{0}'. The virtual IP address is reported as absent. (NLBVIP0003)
    VipFound = Found the virtual IP address '{0}' with subnet mask '{1}' (primary: '{2}'). (NLBVIP0004)
    VipNotFound = The virtual IP address '{0}' does not exist. (NLBVIP0005)
    TestDesiredState = Determining whether the virtual IP address '{0}' is in the desired state. (NLBVIP0006)
    InDesiredState = The virtual IP address '{0}' is in the desired state. (NLBVIP0007)
    NotInDesiredState = The virtual IP address '{0}' is not in the desired state. (NLBVIP0008)
    EnsureMismatch = The virtual IP address '{0}' should be '{1}', but is '{2}'. (NLBVIP0009)
    ClusterRequired = No NLB cluster is bound to interface '{0}'. Create the cluster with the resource NlbClusterDeployment first. (NLBVIP0010)
    AddingVip = Adding the virtual IP address '{0}' with subnet mask '{1}'. (NLBVIP0011)
    RemovingVip = Removing the virtual IP address '{0}'. (NLBVIP0012)
    PrimaryVipChange = The virtual IP address '{0}' is the primary IP address of the cluster. It can not be removed or changed with NlbClusterVip; use the resource NlbClusterDeployment. (NLBVIP0013)
    ChangeVipFailed = Failed to change the virtual IP address '{0}'. (NLBVIP0014)
'@
