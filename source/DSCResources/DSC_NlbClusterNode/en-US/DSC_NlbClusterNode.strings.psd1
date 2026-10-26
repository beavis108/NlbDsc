# Localized resources for DSC_NlbClusterNode

ConvertFrom-StringData @'
    GetCurrentState = Getting the membership of node '{0}' in the NLB cluster on interface '{1}'. (NLBCN0001)
    FeatureNotInstalled = The Windows features for Network Load Balancing are not installed. Node '{0}' is reported as absent. (NLBCN0002)
    ClusterNotFound = No NLB cluster is bound to interface '{0}' of host '{1}'. Node '{2}' is reported as absent. (NLBCN0003)
    NodeFound = Node '{0}' is a member of the NLB cluster '{1}' with state '{2}'. (NLBCN0004)
    NodeNotFound = Node '{0}' is not a member of the NLB cluster '{1}'. (NLBCN0005)
    TestDesiredState = Determining whether node '{0}' is in the desired state. (NLBCN0006)
    InDesiredState = Node '{0}' is in the desired state. (NLBCN0007)
    NotInDesiredState = Node '{0}' should be '{1}', but is '{2}'. (NLBCN0008)
    SetDesiredState = Setting the desired state of node '{0}'. (NLBCN0009)
    RestartRequiredAfterFeatureInstall = A restart is required to finish the installation of the Network Load Balancing features. Node '{0}' will be added after the restart. (NLBCN0010)
    ClusterRequired = No NLB cluster is bound to interface '{0}' of host '{1}'. Create the cluster with the resource NlbClusterDeployment first. (NLBCN0011)
    AddingNode = Adding node '{0}' (interface '{1}') to the NLB cluster '{2}'. (NLBCN0012)
    AddNodeFailed = Failed to add node '{0}' to the NLB cluster '{1}'. Make sure the Windows feature 'NLB' is installed on node '{0}' and that the interface '{2}' exists. (NLBCN0013)
    RemovingNode = Removing node '{0}' from the NLB cluster '{1}'. (NLBCN0014)
    RemoveNodeFailed = Failed to remove node '{0}' from the NLB cluster '{1}'. (NLBCN0015)
    ChangingNodeSettings = Changing the settings '{1}' of node '{0}'. (NLBCN0016)
    ChangeNodeSettingsFailed = Failed to change the settings of node '{0}'. (NLBCN0017)
'@
