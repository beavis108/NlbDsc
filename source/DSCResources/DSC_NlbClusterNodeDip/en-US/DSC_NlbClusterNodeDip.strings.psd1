# Localized resources for DSC_NlbClusterNodeDip

ConvertFrom-StringData @'
    GetCurrentState = Getting the dedicated IP address '{0}' of node '{1}'. (NLBDIP0001)
    FeatureNotInstalled = The Windows features for Network Load Balancing are not installed. The dedicated IP address is reported as absent. (NLBDIP0002)
    ClusterNotFound = No NLB cluster is bound to interface '{0}'. The dedicated IP address is reported as absent. (NLBDIP0003)
    NodeNotFound = Node '{0}' is not a member of the NLB cluster. The dedicated IP address is reported as absent. (NLBDIP0004)
    DipFound = Found the dedicated IP address '{0}' with subnet mask '{1}' on node '{2}'. (NLBDIP0005)
    DipNotFound = The dedicated IP address '{0}' does not exist on node '{1}'. (NLBDIP0006)
    TestDesiredState = Determining whether the dedicated IP address '{0}' is in the desired state. (NLBDIP0007)
    InDesiredState = The dedicated IP address '{0}' is in the desired state. (NLBDIP0008)
    NotInDesiredState = The dedicated IP address '{0}' is not in the desired state. (NLBDIP0009)
    EnsureMismatch = The dedicated IP address '{0}' should be '{1}', but is '{2}'. (NLBDIP0010)
    NodeRequired = Node '{0}' is not a member of an NLB cluster bound to interface '{1}'. (NLBDIP0011)
    AddingDip = Adding the dedicated IP address '{0}' with subnet mask '{1}' to node '{2}'. (NLBDIP0012)
    RemovingDip = Removing the dedicated IP address '{0}' from node '{1}'. (NLBDIP0013)
    ChangeDipFailed = Failed to change the dedicated IP address '{0}' of node '{1}'. (NLBDIP0014)
'@
