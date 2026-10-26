# Localized resources for DSC_NlbClusterPortRuleNode

ConvertFrom-StringData @'
    GetCurrentState = Getting the settings of the port rule for IP address '{0}' and port '{1}' on node '{2}'. (NLBPRN0001)
    FeatureNotInstalled = The Windows features for Network Load Balancing are not installed. (NLBPRN0002)
    ClusterNotFound = No NLB cluster is bound to interface '{0}'. (NLBPRN0003)
    NodeNotFound = Node '{0}' is not a member of the NLB cluster. (NLBPRN0004)
    PortRuleNotFound = No port rule for IP address '{0}' covers the port '{1}'. (NLBPRN0005)
    PortRuleFound = Node '{0}': mode '{1}', equal load '{2}', load weight '{3}', handling priority '{4}', state '{5}'. (NLBPRN0006)
    TestDesiredState = Determining whether the port rule settings of node '{0}' are in the desired state. (NLBPRN0007)
    InDesiredState = The port rule settings of node '{0}' are in the desired state. (NLBPRN0008)
    NotInDesiredState = The port rule settings of node '{0}' are not in the desired state. (NLBPRN0009)
    PortRuleRequired = The port rule for IP address '{0}' and port '{1}' does not exist on node '{2}'. Create it with the resource NlbClusterPortRule first. (NLBPRN0010)
    SettingIgnored = The property '{0}' is ignored, because it does not apply to port rules with the filtering mode '{1}'. (NLBPRN0011)
    SettingLoadWeight = Setting the load weight of node '{0}' to '{1}'. (NLBPRN0012)
    SettingEqualLoad = Setting equal load distribution for node '{0}'. (NLBPRN0013)
    SettingHandlingPriority = Setting the handling priority of node '{0}' to '{1}'. (NLBPRN0014)
    EnablingPortRule = Enabling the port rule on node '{0}'. (NLBPRN0015)
    DisablingPortRule = Disabling the port rule on node '{0}' (drain: '{1}'). (NLBPRN0016)
    ChangeFailed = Failed to change the port rule settings of node '{0}'. (NLBPRN0017)
    EqualLoadAndLoadWeight = The properties EqualLoad = $true and LoadWeight can not be used together. (NLBPRN0018)
    EqualLoadFalseRequiresLoadWeight = The property EqualLoad = $false requires the property LoadWeight. (NLBPRN0019)
'@
