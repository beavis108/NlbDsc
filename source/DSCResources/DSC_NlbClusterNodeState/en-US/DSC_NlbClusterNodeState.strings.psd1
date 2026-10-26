# Localized resources for DSC_NlbClusterNodeState

ConvertFrom-StringData @'
    GetCurrentState = Getting the host state of node '{0}'. (NLBNS0001)
    FeatureNotInstalled = The Windows features for Network Load Balancing are not installed. (NLBNS0002)
    ClusterNotFound = No NLB cluster is bound to interface '{0}' of host '{1}'. (NLBNS0003)
    NodeNotFound = Node '{0}' is not a member of the NLB cluster. (NLBNS0004)
    NodeStateFound = Node '{0}' has the state '{1}' (host state '{2}'). (NLBNS0005)
    TestDesiredState = Determining whether node '{0}' has the host state '{1}'. (NLBNS0006)
    InDesiredState = Node '{0}' has the desired host state '{1}'. (NLBNS0007)
    NotInDesiredState = Node '{0}' should have the host state '{1}', but has '{2}'. (NLBNS0008)
    NodeRequired = Node '{0}' is not a member of an NLB cluster bound to interface '{1}'. Add the node with the resource NlbClusterNode first. (NLBNS0009)
    ResumingNode = Resuming node '{0}'. (NLBNS0010)
    StartingNode = Starting node '{0}'. (NLBNS0011)
    StoppingNode = Stopping node '{0}' (drain: '{1}'). (NLBNS0012)
    SuspendingNode = Suspending node '{0}'. (NLBNS0013)
    ChangeStateFailed = Failed to change the host state of node '{0}' to '{1}'. (NLBNS0014)
'@
